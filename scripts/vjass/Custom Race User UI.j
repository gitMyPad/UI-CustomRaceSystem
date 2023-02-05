//$ noimport
library CustomRaceUserUI requires /*

     --------------------------
    */  CustomRaceCore,     /*
    --------------------------

    --------------------------
    */  CustomRaceUI,       /*
    --------------------------

    ------------------------------
    */  CustomRacePSelection,   /*
    ------------------------------

    ----------------------------------
    */  CustomRaceMatchConditions,  /*
    ----------------------------------

    ----------------------------------
    */  CustomRaceMatch,            /*
    ----------------------------------

    ----------------------------------
    */  CustomRaceObserverUI,       /*
    ----------------------------------

    ----------------------
    */  Init,           /*
    ----------------------

    ------------------------------
    */  GameStatus              /*
    ------------------------------

    ------------------------------
    */  optional FrameLoader    /*
    ------------------------------

     --------------------------------------------------------------
    |
    |   Custom Race User UI
    |
    |--------------------------------------------------------------
    |
    |   A library that handles event processing of the generated
    |   framehandles, and the selection of desired factions and
    |   whatnot.
    |
    |   This library outsources the actual creation of most of the
    |   frame handles to the Custom Race UI library.
    |
     --------------------------------------------------------------
*/

globals
    //  Discoveries made by Luashine on the tick rate of the game suggest
    //  that the game updates at a frequency of 50 Hz. Further insights on
    //  tick rate and all related stuff can be found here:
    //  https://www.hiveworkshop.com/threads/high-speed-triggers-or-a-slow-triggerregistertimereventperiodic.341024/
    private constant real INTERVAL          = 1.0 / 50.0
    private constant real WAIT_DURATION     = 30.0
    private constant real EASE_IN           = 1.75   // 0.5
    private constant real EASE_OUT          = 0.75   // 0.5
    private constant real FINALIZE_DELAY    = 0.50   // 0.5

    private integer  WAIT_MAX_TICKS     = R2I(WAIT_DURATION / INTERVAL + 0.01)
    private integer  EASE_IN_TICKS      = R2I(EASE_IN / INTERVAL + 0.01)
    private integer  EASE_OUT_TICKS     = R2I(EASE_OUT / INTERVAL + 0.01)

    private constant integer MODE_BAR_UPDATE    = 1
    private constant integer MODE_EASE_IN       = 2
    private constant integer MODE_EASE_OUT      = 4

    private constant real FRAME_START_DELAY = 0.25

    private constant real DECAY_RATE        = 8.0
    private constant real OSCILLATE_RATE    = 2.0
    private constant real DELAY             = 0.15
    private constant real E                 = 2.7182818
endglobals

private constant function GetDefaultTechtreeIconTexture takes nothing returns string
    return "UI\\Widgets\\EscMenu\\Human\\editbox-background.blp"
endfunction
//  =============================================================================   //
//      Originally, the ease in and out functions were going to have different
//      responses. However, I liked the final ease in response so much that
//      I used it all throughout instead.
//  =============================================================================   //
private struct DecayResponse extends array
    private  static constant integer MAX_STEPS      = 1000
    private  static real STEP_SIZE                  = 1.0 / I2R(MAX_STEPS)
    readonly static real array value

    private static method init takes nothing returns nothing
        local integer i         = 1
        local real a            = STEP_SIZE
        local real mult         = Pow(E, -a*DECAY_RATE)
        local real curMult      = mult
        set value[0]            = 0.0
        loop
            exitwhen i > MAX_STEPS
            set value[i]        = 1 - curMult*Cos(2*bj_PI*OSCILLATE_RATE*a)
            set curMult         = curMult*mult
            set i               = i + 1
            set a               = a + STEP_SIZE
        endloop
        set value[MAX_STEPS]    = 1.0
    endmethod

    static method getValue takes real x returns real
        local integer index
        local real    modulo
        if x <= 0.0 then
            return 0.0
        elseif x >= 1.0 then
            return 1.0
        endif
        set index   = R2I(x / STEP_SIZE)
        set modulo  = ModuloReal(x, STEP_SIZE) / STEP_SIZE
        return value[index]*(1 - modulo) + value[index + 1]*(modulo)
    endmethod
    implement Init
endstruct

private function StepResponse takes real x returns real
    if x > 0 then
        return 1.0
    endif
    return 0.0
endfunction
private function BarUpdateResponse takes real x returns real
    return 1.0 - x
endfunction
private function EaseInResponse takes real x returns real
    set x   = x - 0.25
    return DecayResponse.getValue(x)
endfunction
private function EaseOutResponse takes real x returns real
    return (x*(x*(x*(x*(0.20*x-0.55)+0.47)-0.1))) / 0.02
endfunction
private function EaseInPosResponse takes real x returns real
    return EaseInResponse(x)
endfunction
private function EaseOutPosResponse takes real x returns real
    return EaseOutResponse(x)
endfunction

private constant function GetMainFrameStartCenterX takes nothing returns real
    return CustomRaceUI_GetMainFrameCenterX()
endfunction
private constant function GetMainFrameStartCenterY takes nothing returns real
    return 0.30
endfunction

private struct FrameInterpolation extends array
    readonly static timer timer         = CreateTimer()
    readonly static player localPlayer  = null
    readonly static boolean isReplay    = false

    private static constant integer  MAX_POWER_INDEX    = 3
    private static integer  instanceCount               = 0
    private static integer  array powersOf2
    private static integer  array tickMap
    private static thistype array activeInstances
    
    static integer array currentTicks
    static integer array maxTicks

    readonly integer mode
    readonly integer activeTicks

    private static method getPowerIndex takes integer mode returns integer
        if mode == MODE_EASE_OUT then
            return 3
        elseif mode == MODE_EASE_IN then
            return 2
        elseif mode == MODE_BAR_UPDATE then
            return 1
        endif
        return 0
    endmethod
    private method setTick takes integer mode, integer newval returns nothing
        set mode                                                = thistype.getPowerIndex(mode)
        set currentTicks[MAX_POWER_INDEX*integer(this) + mode]  = newval
    endmethod
    private method getTick takes integer mode returns integer
        set mode                                                = thistype.getPowerIndex(mode)
        return currentTicks[MAX_POWER_INDEX*integer(this) + mode]
    endmethod
    private method getMaxTick takes integer mode returns integer
        set mode                                                = thistype.getPowerIndex(mode)
        return maxTicks[MAX_POWER_INDEX*integer(this) + mode]
    endmethod

    private static method onUpdate takes nothing returns nothing
        local integer i         = 1
        local thistype this
        local real   ratio
        local real   posRatio
        local real   cx
        local real   cy
        local player whichPlayer
        loop
            exitwhen i > instanceCount
            set this        = activeInstances[i]
            set whichPlayer = Player(integer(this))
            if BlzBitAnd(this.mode, MODE_BAR_UPDATE) != 0 then
                call this.setTick(MODE_BAR_UPDATE, this.getTick(MODE_BAR_UPDATE) + 1)
                set ratio   = I2R(this.getTick(MODE_BAR_UPDATE)) / /*
                           */ I2R(this.getMaxTick(MODE_BAR_UPDATE))
                set ratio   = BarUpdateResponse(ratio)
                if this.getTick(MODE_BAR_UPDATE) >= this.getMaxTick(MODE_BAR_UPDATE) then
                    set this.mode   = this.mode - MODE_BAR_UPDATE
                endif
                if thistype.localPlayer == whichPlayer then
                    call CustomRaceInterface.setBarProgress(ratio)
                endif
            endif
            if BlzBitAnd(this.mode, MODE_EASE_IN) != 0 then
                if (thistype.localPlayer == whichPlayer) and /*
                */ (not CustomRaceInterface.isMainVisible()) then
                    if (not isReplay) then
                        call CustomRaceInterface.setMainVisible(true)
                    endif
                endif

                call this.setTick(MODE_EASE_IN, this.getTick(MODE_EASE_IN) + 1)
                set ratio       = I2R(this.getTick(MODE_EASE_IN)) / /*
                               */ I2R(this.getMaxTick(MODE_EASE_IN))
                set posRatio    = EaseInPosResponse(ratio)
                set ratio       = EaseInResponse(ratio)
                set cx          = GetMainFrameStartCenterX()*(1 - posRatio) + /*
                               */ CustomRaceUI_GetMainFrameCenterX()*posRatio
                set cy          = GetMainFrameStartCenterY()*(1 - posRatio) + /*
                               */ CustomRaceUI_GetMainFrameCenterY()*posRatio

                if thistype.localPlayer == whichPlayer then
                    call CustomRaceInterface.setMainAlpha(ratio)
                    call CustomRaceInterface.setMainPos(cx, cy)
                endif
                if this.getTick(MODE_EASE_IN) >= this.getMaxTick(MODE_EASE_IN) then
                    set this.mode   = this.mode - MODE_EASE_IN
                endif

            elseif BlzBitAnd(this.mode, MODE_EASE_OUT) != 0 then
                call this.setTick(MODE_EASE_OUT, this.getTick(MODE_EASE_OUT) + 1)
                set ratio       = I2R(this.getTick(MODE_EASE_OUT)) / /*
                               */ I2R(this.getMaxTick(MODE_EASE_OUT))
                set posRatio    = EaseOutPosResponse(ratio)
                set ratio       = 1.0 - RMinBJ(EaseOutResponse(ratio), 1.0)
                set cx          = CustomRaceUI_GetMainFrameCenterX()*(1 - posRatio) + /*
                               */ GetMainFrameStartCenterX()*posRatio
                set cy          = CustomRaceUI_GetMainFrameCenterY()*(1 - posRatio) + /*
                               */ GetMainFrameStartCenterY()*posRatio

                if thistype.localPlayer == whichPlayer then
                    call CustomRaceInterface.setMainAlpha(ratio)
                    call CustomRaceInterface.setMainPos(cx, cy)
                endif
                if this.getTick(MODE_EASE_OUT) >= this.getMaxTick(MODE_EASE_OUT) then
                    set this.mode   = this.mode - MODE_EASE_OUT
                    if (thistype.localPlayer == whichPlayer) then
                        if (not isReplay) then
                            call CustomRaceInterface.setMainVisible(false)
                        endif
                        call CustomRaceInterface.setMainAlpha(1.0)
                    endif
                endif
            endif
            //  Remove this instance from the instance list
            if this.mode == 0 then
                set activeInstances[i]  = activeInstances[instanceCount]
                set instanceCount       = instanceCount - 1
                set i                   = i - 1
            endif
            set i       = i + 1
        endloop
        if instanceCount <= 0 then
            call PauseTimer(timer)
        endif
    endmethod

    private static method startTimer takes nothing returns nothing
        if instanceCount == 1 then
            call TimerStart(timer, INTERVAL, true, function thistype.onUpdate)
        endif
    endmethod

    private method setCurrentTicks takes integer mode returns nothing
        set mode                                                = thistype.getPowerIndex(mode)
        set currentTicks[MAX_POWER_INDEX*integer(this) + mode]  = 0
        set maxTicks[MAX_POWER_INDEX*integer(this) + mode]      = tickMap[mode]
    endmethod

    method isTransitioning takes integer mode returns boolean
        return BlzBitAnd(this.mode, mode) != 0
    endmethod

    method stop takes integer mode returns boolean
        if not this.isTransitioning(mode) then
            return false
        endif
        call this.setTick(mode, this.getTick(mode) - 1)
        set this.mode   = this.mode - mode
        return true
    endmethod

    method request takes integer mode returns boolean
        if BlzBitAnd(this.mode, mode) != 0 then
            return false
        endif
        if this.mode == 0 then
            set instanceCount                   = instanceCount + 1
            set activeInstances[instanceCount]  = this
            call thistype.startTimer()
        endif
        set this.mode   = this.mode + mode
        call this.setCurrentTicks(mode)
        return true
    endmethod

    static method [] takes player whichPlayer returns thistype
        return thistype(GetPlayerId(whichPlayer))
    endmethod

    private static method init takes nothing returns nothing
        set powersOf2[1]    = 1
        set powersOf2[2]    = 2
        set powersOf2[3]    = 4
        set tickMap[1]      = WAIT_MAX_TICKS
        set tickMap[2]      = EASE_IN_TICKS
        set tickMap[3]      = EASE_OUT_TICKS
        set localPlayer     = GetLocalPlayer()
        set isReplay        = GetGameStatus() == GAME_STATUS_REPLAY
    endmethod
    implement Init
endstruct

//  ==========================================================================  //
//                      UI Drawing API                                          //
//  ==========================================================================  //
private function GetObjectIdDescription takes integer objectID returns string
    return BlzGetAbilityExtendedTooltip(objectID, 0)
endfunction
private function GetObjectIdIcon takes integer objectID returns string
    return BlzGetAbilityIcon(objectID)
endfunction
private function GetObjectIdFromChunk takes integer i, integer j, integer baseTechID, CustomRace faction /*
                                   */ returns integer
    if (i == 1) then
        return faction.getUnit(baseTechID + j)
    elseif (i == 2) then
        return faction.getStructure(baseTechID + j)
    elseif (i == 3) then
        return faction.getHero(baseTechID + j)
    endif
    return 0
endfunction
private function GetTechtreeArrowMaxValue takes integer i, CustomRace faction returns integer
    if (i == 1) then
        return faction.getUnitMaxIndex()
    elseif (i == 2) then
        return faction.getStructureMaxIndex()
    elseif (i == 3) then
        return faction.getHeroMaxIndex()
    endif
    return 0
endfunction
private function CheckTechtreeChunkForDraw takes integer i, CustomRace faction returns boolean
    return GetTechtreeArrowMaxValue(i, faction) > 0
endfunction
private function CheckTechtreeIconForDraw takes integer i, integer j, CustomRace faction, /*
                                             */ CustomRacePSelection obj returns boolean
    //  Draw units?
    local integer max   = GetTechtreeArrowMaxValue(i, faction)
    return obj.getBaseTechID(i) + j <= max
endfunction
private function DrawTechtreeIcon takes player whichPlayer, integer i, integer j, integer baseTechID, /*
                                     */ CustomRace faction returns nothing
    local integer objectID      = GetObjectIdFromChunk(i, j, baseTechID, faction)
    local integer baseIndex     = (i-1)*CustomRaceInterface.iconsPerChunk
    local string desc           = ""
    /*
    if (i == 1) then
        set objectID    = faction.getUnit(baseTechID + j)
    elseif (i == 2) then
        set objectID    = faction.getStructure(baseTechID + j)
    endif
    */
    set desc            = GetObjectIdIcon(objectID)
    if FrameInterpolation.localPlayer == whichPlayer then
        call CustomRaceInterface.setTechtreeIconVisible(baseIndex + j, true)
        call CustomRaceInterface.setTechtreeIconDisplayByID(baseIndex + j, desc)
    endif
endfunction
private function DrawUIFromPlayerData takes player whichPlayer, CustomRacePSelection obj returns nothing
    local integer i             = 1
    local integer j             = 0
    local integer objectID      = 0
    local integer baseIndex     = 0
    local race pRace            = GetPlayerRace(whichPlayer)
    local CustomRace faction    = 0
    //  Draw the choice buttons first
    if FrameInterpolation.localPlayer == whichPlayer then
        call CustomRaceInterface.setChoiceArrowVisible(true, obj.baseChoice != 0)
        call CustomRaceInterface.setSliderVisible(CustomRace.getRaceFactionCount(pRace) > CustomRaceUI_GetMaxDisplayChoices())
        call BlzFrameSetEnable(CustomRaceInterface.confirmFrame, obj.faction != 0)
    endif
    loop
        exitwhen i > CustomRaceUI_GetMaxDisplayChoices()
        if obj.baseChoice + i > CustomRace.getRaceFactionCount(pRace) then
            if FrameInterpolation.localPlayer == whichPlayer then
                call CustomRaceInterface.setChoiceName(i, "")
                call CustomRaceInterface.setChoiceButtonVisible(i, false)
            endif
        else
            if (FrameInterpolation.localPlayer == whichPlayer) then
                call CustomRaceInterface.setChoiceArrowVisible(false, /*
                                                            */ obj.baseChoice + i < CustomRace.getRaceFactionCount(pRace))
            endif
            set faction = CustomRace.getRaceFaction(pRace, obj.baseChoice + i)
            if FrameInterpolation.localPlayer == whichPlayer then
                call CustomRaceInterface.setChoiceName(i, faction.name)
                call CustomRaceInterface.setChoiceButtonVisible(i, true)
            endif
        endif
        set i = i + 1
    endloop
    //  If a faction was selected, show the name, display
    //  and race description, and continue with techtree
    //  visuals. Otherwise, hide techtree visuals.
    if obj.focusFaction != 0 then
        set faction = CustomRace.getRaceFaction(pRace, obj.baseChoice + obj.focusFaction)
        if FrameInterpolation.localPlayer == whichPlayer then
            call CustomRaceInterface.setFactionNameVisible(true)
            call CustomRaceInterface.setFactionName(faction.name)
            call CustomRaceInterface.setDescription(faction.desc)
            call CustomRaceInterface.setFactionDisplay(faction.racePic)
        endif
    else
        set faction = 0
        if FrameInterpolation.localPlayer == whichPlayer then
            call CustomRaceInterface.setFactionNameVisible(false)
            call CustomRaceInterface.setFactionName("")
            call CustomRaceInterface.setDescription("")
            call CustomRaceInterface.setFactionDisplay("")
        endif
    endif
    //  Since no faction in particular was selected, terminate
    //  the drawing process here by hiding the techtree chunks.
    if (faction == 0) then
        set i   = 1
        loop
            exitwhen i > CustomRaceUI_GetTechtreeChunkCount()
            call obj.setBaseTechID(i, 0)
            if FrameInterpolation.localPlayer == whichPlayer then
                call CustomRaceInterface.setTechtreeChunkVisible(i, false)
            endif
            set i = i + 1
        endloop
        set obj.focusTechtree       = 0
        set obj.focusTechID         = 0
        set obj.techtree            = 0
        set obj.focusTechtreeStack  = 0
        if FrameInterpolation.localPlayer == whichPlayer then
            call CustomRaceInterface.setTooltipVisible(false)
        endif
        return
    endif
    //  Draw the techtree chunks if data exists
    set i   = 1
    loop
        exitwhen i > CustomRaceUI_GetTechtreeChunkCount()
        loop
            if CheckTechtreeChunkForDraw(i, faction) then
                if FrameInterpolation.localPlayer == whichPlayer then
                    call CustomRaceInterface.setTechtreeChunkVisible(i, true)
                endif
            else
                /*
                if obj.focusTechtree == i then
                    set obj.focusTechtree       = 0
                    set obj.focusTechID         = 0
                    set obj.techtree            = 0
                    set obj.focusTechtreeStack  = 0
                    call obj.setBaseTechID(i, 0)
                endif
                */
                if FrameInterpolation.localPlayer == whichPlayer then
                    call CustomRaceInterface.setTechtreeChunkVisible(i, false)
                endif
                exitwhen true
            endif
            set j           = 1
            set baseIndex   = (i-1)*CustomRaceInterface.iconsPerChunk
            //  Draw the choice buttons first
            if FrameInterpolation.localPlayer == whichPlayer then
                call CustomRaceInterface.setTechtreeArrowVisible(i, true, obj.getBaseTechID(i) != 0)
            endif
            loop
                exitwhen j > CustomRaceInterface.iconsPerChunk
                if CheckTechtreeIconForDraw(i, j, faction, obj) then
                    call DrawTechtreeIcon(whichPlayer, i, j, obj.getBaseTechID(i), faction)
                    if (FrameInterpolation.localPlayer == whichPlayer) then
                        call CustomRaceInterface.setTechtreeArrowVisible(i, false, /*
                                                                      */ (obj.getBaseTechID(i) + j) < /*
                                                                      */ (GetTechtreeArrowMaxValue(i, faction)))
                    endif
                else
                    if (FrameInterpolation.localPlayer == whichPlayer) then
                        call CustomRaceInterface.setTechtreeIconVisible(baseIndex + j, false)
                    endif
                endif
                set j = j + 1
            endloop
            exitwhen true
        endloop
        set i = i + 1
    endloop
    //  If a techtree icon was selected, show the name, display
    //  and race description.
    if FrameInterpolation.localPlayer == whichPlayer then
        call CustomRaceInterface.setTooltipVisible(obj.focusTechID != 0)
        call CustomRaceInterface.setTooltipName("")
        call CustomRaceInterface.setTooltipDesc("")
    endif
    if (obj.focusTechID != 0) then
        set objectID    = GetObjectIdFromChunk(obj.focusTechtree, obj.focusTechID, /*
                                            */ obj.getBaseTechID(obj.focusTechtree), faction)
        if FrameInterpolation.localPlayer == whichPlayer then
            call CustomRaceInterface.setTooltipName(GetObjectName(objectID))
            call CustomRaceInterface.setTooltipDesc(GetObjectIdDescription(objectID))
        endif
    endif
endfunction

//  ==========================================================================  //
//                      Sound Generating Functions                              //
//  ==========================================================================  //
globals
    private sound tempSound         = null
endglobals

private function GenerateClunkDownSound takes nothing returns sound
    set tempSound   = CreateSound("Sound\\Interface\\LeftAndRightGlueScreenPopDown.wav", false, false, false, 10, 10, "DefaultEAXON")
    call SetSoundParamsFromLabel(tempSound, "BothGlueScreenPopDown")
    call SetSoundDuration(tempSound, 2246)
    call SetSoundVolume(tempSound, 127)
    return tempSound
endfunction
private function GenerateClunkUpSound takes nothing returns sound
    set tempSound   = CreateSound("Sound\\Interface\\LeftAndRightGlueScreenPopUp.wav", false, false, false, 10, 10, "DefaultEAXON")
    call SetSoundParamsFromLabel(tempSound, "BothGlueScreenPopUp")
    call SetSoundDuration(tempSound, 1953)
    call SetSoundVolume(tempSound, 127)
    return tempSound
endfunction
private function GenerateClickSound takes nothing returns sound
    set tempSound   = CreateSound("Sound\\Interface\\MouseClick1.wav", false, false, false, 10, 10, "")
    call SetSoundParamsFromLabel(tempSound, "InterfaceClick")
    call SetSoundDuration(tempSound, 239)
    return tempSound
endfunction
private function GenerateWarningSound takes nothing returns sound
    set tempSound = CreateSound("Sound\\Interface\\CreepAggroWhat1.wav", false, false, false, 10, 10, "DefaultEAXON")
    call SetSoundParamsFromLabel(tempSound, "CreepAggro")
    call SetSoundDuration(tempSound, 1236)
    return tempSound
endfunction
private function PlaySoundForPlayer takes sound snd, player whichPlayer returns nothing
    if FrameInterpolation.localPlayer == whichPlayer then
        call SetSoundVolume(snd, 127)
    else
        call SetSoundVolume(snd, 0)
    endif
    call StartSound(snd)
    call KillSoundWhenDone(snd)
endfunction
//  ==========================================================================  //

//  ==========================================================================  //
globals
    private code  onDefaultFinalize = null
    private timer finalizer         = null
endglobals

private function IsFrameUseable takes player whichPlayer returns boolean
    return (not FrameInterpolation[whichPlayer].isTransitioning(MODE_EASE_IN)) and /*
        */ (not FrameInterpolation[whichPlayer].isTransitioning(MODE_EASE_OUT))
endfunction
private function HideCustomFrame takes player whichPlayer returns nothing
    if FrameInterpolation[whichPlayer].isTransitioning(MODE_EASE_IN) then
        return
    endif
    call PlaySoundForPlayer(GenerateClunkUpSound(), whichPlayer)
    call FrameInterpolation[whichPlayer].request(MODE_EASE_OUT)
endfunction
private function ShowCustomFrame takes player whichPlayer returns nothing
    if FrameInterpolation[whichPlayer].isTransitioning(MODE_EASE_OUT) then
        return
    endif
    call PlaySoundForPlayer(GenerateClunkDownSound(), whichPlayer)
    call FrameInterpolation[whichPlayer].request(MODE_EASE_IN)
endfunction
//  ==========================================================================  //

//  ==========================================================================  //
private function HideCustomFrameEnum takes nothing returns nothing
    call HideCustomFrame(GetEnumPlayer())
endfunction
private function HideCustomFrameAll takes nothing returns nothing
    call ForForce(CustomRaceForce.activePlayers, function HideCustomFrameEnum)
endfunction
private function ShowCustomFrameEnum takes nothing returns nothing
    if CustomRacePSelection.hasChoicedPlayer(GetEnumPlayer()) then
        call ShowCustomFrame(GetEnumPlayer())
    endif
endfunction
private function ShowCustomFrameAll takes nothing returns nothing
    call ForForce(CustomRaceForce.activePlayers, function ShowCustomFrameEnum)
endfunction
//  ==========================================================================  //

//  ==========================================================================  //
private function OnBarTimerStart takes nothing returns nothing
    local integer i = 1
    call PauseTimer(GetExpiredTimer())
    call DestroyTimer(GetExpiredTimer())
    //  Apply timer only when in a multiplayer setting
    //  or when the following flag is true.
    if (not CustomRaceMatch_APPLY_TIMER_IN_SINGLE_PLAYER) and /*
    */ (CustomRacePSelection.isSinglePlayer) then
        return
    endif
    loop
        exitwhen i > CustomRacePSelection.choicedPlayerSize
        call FrameInterpolation[CustomRacePSelection.choicedPlayers[i]].request(MODE_BAR_UPDATE)
        set i = i + 1
    endloop
    set finalizer   = CreateTimer()
    call TimerStart(finalizer, WAIT_DURATION, false, onDefaultFinalize)
endfunction
private function OnPrepUI takes nothing returns nothing
    call PauseTimer(GetExpiredTimer())
    call DestroyTimer(GetExpiredTimer())
    call TimerStart(CreateTimer(), EASE_IN, false, function OnBarTimerStart)
    call ShowCustomFrameAll()
endfunction
private function PrepUI takes nothing returns nothing
    local integer i = 1
    loop
        exitwhen i > CustomRaceUI_GetTechtreeChunkCount()
        call CustomRaceInterface.setTechtreeChunkVisible(i, false)
        set i = i + 1
    endloop
    set i   = 1
    loop
        exitwhen i > CustomRaceUI_GetMaxDisplayChoices()
        call CustomRaceInterface.setChoiceButtonVisible(i, false)
        set i = i + 1
    endloop
    call CustomRaceInterface.setSliderVisible(false)
    call CustomRaceInterface.setFactionNameVisible(false)
    call CustomRaceInterface.setFactionDisplay("")
    call CustomRaceInterface.setBarProgress(1.00)
    call CustomRaceInterface.setTooltipVisible(false)
    //  No players with a choice in their faction..
    if CustomRacePSelection.choicedPlayerSize < 1 then
        return
    endif
    call TimerStart(CreateTimer(), FRAME_START_DELAY, false, function OnPrepUI)
endfunction
//  ==========================================================================  //

//  ==========================================================================  //
private struct UIFrameEvents extends array
    readonly static trigger abandonTrig  = CreateTrigger()
    //  ==========================================================================  //
    //                      Finalization Events                                     //
    //  ==========================================================================  //
    static method onFinalizeEnd takes nothing returns nothing
        call DisableTrigger(thistype.abandonTrig)
        call DestroyTrigger(thistype.abandonTrig)
        call CustomRaceMatch_MeleeInitializationFinish()
    endmethod
    static method finalize takes nothing returns nothing
        call TimerStart(CreateTimer(), FINALIZE_DELAY + EASE_OUT, false, /*
                    */  function thistype.onFinalizeEnd)
    endmethod
    static method onFinalize takes nothing returns nothing
        local player indexPlayer
        local CustomRacePSelection obj
        local integer i
        loop
            exitwhen CustomRacePSelection.choicedPlayerSize < 1
            set indexPlayer             = CustomRacePSelection.choicedPlayers[CustomRacePSelection.choicedPlayerSize]
            set obj                     = CRPSelection[indexPlayer]
            set obj.focusFaction        = 0
            set obj.faction             = 0
            set obj.focusFactionStack   = 0
            set obj.techtree            = 0
            set obj.focusTechtree       = 0
            set obj.focusTechID         = 0
            set obj.focusTechtreeStack  = 0
            set i = 1
            loop
                exitwhen i > CustomRaceUI_GetTechtreeChunkCount()
                call obj.setBaseTechID(i, 0)
                set i = i + 1
            endloop
            call DrawUIFromPlayerData(indexPlayer, obj)
            set obj.faction             = 1
            call CustomRacePSelection.removeChoicedPlayer(indexPlayer)
            call CustomRacePSelection.addUnchoicedPlayer(indexPlayer)
            call HideCustomFrame(indexPlayer)
        endloop
        call thistype.finalize()
    endmethod
    static method onExpireFinalize takes nothing returns nothing
        local timer whichTimer          = GetExpiredTimer()
        call PauseTimer(whichTimer)
        call DestroyTimer(whichTimer)
        set whichTimer                  = null
        call thistype.onFinalize()
    endmethod

    //  ==========================================================================  //
    //                      Enter and Leave Events                                  //
    //  ==========================================================================  //
    static method onChoiceButtonEnter takes nothing returns nothing
        local framehandle zabutton      = BlzGetTriggerFrame()
        local integer i                 = CustomRaceInterface.getChoiceButtonID(zabutton)
        local player  trigPlayer        = GetTriggerPlayer()
        local CustomRacePSelection obj  = CRPSelection[trigPlayer]
        if obj.focusFactionStack < 1 then
            set obj.focusFaction        = i
        endif
        set obj.focusFactionStack       = obj.focusFactionStack + 1
        if not IsFrameUseable(trigPlayer) then
            return
        endif
        call DrawUIFromPlayerData(trigPlayer, obj)
    endmethod
    static method onChoiceButtonLeave takes nothing returns nothing
        local framehandle zabutton      = BlzGetTriggerFrame()
        local integer i                 = CustomRaceInterface.getChoiceButtonID(zabutton)
        local player  trigPlayer        = GetTriggerPlayer()
        local CustomRacePSelection obj  = CRPSelection[trigPlayer]
        //  obj.focusFactionStack can only be equal to 2
        //  if a choice button was already selected.
        if obj.focusFactionStack < 2 then
            set obj.focusFaction        = 0
        endif
        set obj.focusFactionStack       = obj.focusFactionStack - 1
        if not IsFrameUseable(trigPlayer) then
            return
        endif
        call DrawUIFromPlayerData(trigPlayer, obj)
    endmethod
    static method onTechtreeIconEnter takes nothing returns nothing
        local framehandle zabutton      = BlzGetTriggerFrame()
        local integer i                 = CustomRaceInterface.getTechtreeIconID(zabutton)
        local integer curChunk          = CustomRaceInterface.getChunkFromIndex(i)
        local player  trigPlayer        = GetTriggerPlayer()
        local CustomRacePSelection obj  = CRPSelection[trigPlayer]
        if obj.focusTechtreeStack < 1 then
            set obj.focusTechtree       = curChunk
            set obj.focusTechID         = ModuloInteger(i, CustomRaceInterface.iconsPerChunk)
            if obj.focusTechID == 0 then
                set obj.focusTechID     = CustomRaceInterface.iconsPerChunk
            endif
        endif
        set obj.focusTechtreeStack  = obj.focusTechtreeStack + 1
        if not IsFrameUseable(trigPlayer) then
            return
        endif
        call DrawUIFromPlayerData(trigPlayer, obj)
    endmethod
    static method onTechtreeIconLeave takes nothing returns nothing
        local framehandle zabutton      = BlzGetTriggerFrame()
        local integer i                 = CustomRaceInterface.getTechtreeIconID(zabutton)
        local integer curChunk          = CustomRaceInterface.getChunkFromIndex(i)
        local player  trigPlayer        = GetTriggerPlayer()
        local CustomRacePSelection obj  = CRPSelection[trigPlayer]
        if obj.focusTechtreeStack < 2 then
            set obj.focusTechtree   = 0
            set obj.focusTechID     = 0
        endif
        set obj.focusTechtreeStack  = obj.focusTechtreeStack - 1
        if not IsFrameUseable(trigPlayer) then
            return
        endif
        call DrawUIFromPlayerData(trigPlayer, obj)
    endmethod
    //  ==========================================================================  //
    //                                Click Events                                  //
    //  ==========================================================================  //
    static method onChoiceButtonClick takes nothing returns nothing
        local framehandle zabutton      = BlzGetTriggerFrame()
        local integer i                 = CustomRaceInterface.getChoiceButtonID(zabutton)
        local integer j                 = 0
        local player  trigPlayer        = GetTriggerPlayer()
        local CustomRacePSelection obj  = CRPSelection[trigPlayer]
        //  obj.focusFactionStack can only be equal to 2
        //  if a choice button was already selected.
        if obj.faction == 0 then
            set obj.focusFactionStack   = obj.focusFactionStack + 1
            set obj.focusFaction        = i
            set obj.faction             = obj.focusFaction
        else
            set obj.focusFactionStack   = obj.focusFactionStack - 1
            if FrameInterpolation.localPlayer == trigPlayer then
                call BlzFrameSetEnable(CustomRaceInterface.getChoiceButton(obj.focusFaction), false)
                call BlzFrameSetEnable(CustomRaceInterface.getChoiceButton(obj.focusFaction), true)
            endif
            if i != obj.focusFaction then
                set obj.focusFactionStack   = obj.focusFactionStack + 1
                set obj.focusFaction        = i
                set obj.faction             = i
                //  Update techtree tooltip and icons as well
                set obj.focusTechtree       = 0
                set obj.focusTechID         = 0
                set obj.techtree            = 0
                set obj.focusTechtreeStack  = 0
                set j   = 1
                loop
                    exitwhen j > CustomRaceUI_GetTechtreeChunkCount()
                    call obj.setBaseTechID(j, 0)
                    set j   = j + 1
                endloop
            else
                set obj.faction             = 0
            endif
        endif
        if not IsFrameUseable(trigPlayer) then
            return
        endif
        call DrawUIFromPlayerData(trigPlayer, obj)
        call CustomRaceObserverUI_RenderFrame()
    endmethod
    static method onTechtreeIconClick takes nothing returns nothing
        local framehandle zabutton      = BlzGetTriggerFrame()
        local integer i                 = CustomRaceInterface.getTechtreeIconID(zabutton)
        local integer index             = 0
        local integer curChunk          = CustomRaceInterface.getChunkFromIndex(i)
        local player  trigPlayer        = GetTriggerPlayer()
        local CustomRacePSelection obj  = CRPSelection[trigPlayer]
        if obj.techtree == 0 then
            set obj.focusTechtreeStack  = obj.focusTechtreeStack + 1
            set obj.focusTechtree       = curChunk
            set obj.focusTechID         = ModuloInteger(i, CustomRaceInterface.iconsPerChunk)
            if obj.focusTechID == 0 then
                set obj.focusTechID     = CustomRaceInterface.iconsPerChunk
            endif
            set obj.techtree            = obj.focusTechID
        else
            set obj.focusTechtreeStack  = obj.focusTechtreeStack - 1
            set index                   = (obj.focusFaction-1)
            set index                   = index*CustomRaceInterface.iconsPerChunk + obj.focusTechID
            if FrameInterpolation.localPlayer == trigPlayer then
                call BlzFrameSetEnable(CustomRaceInterface.getTechtreeIconRaw(index), false)
                call BlzFrameSetEnable(CustomRaceInterface.getTechtreeIconRaw(index), true)
            endif
            set i                       = ModuloInteger(i, CustomRaceInterface.iconsPerChunk)
            if i == 0 then
                set i                   = CustomRaceInterface.iconsPerChunk
            endif
            if i != obj.focusTechID then
                set obj.focusTechtreeStack  = obj.focusTechtreeStack + 1
                set obj.focusTechtree       = curChunk
                set obj.focusTechID         = i
                set obj.techtree            = obj.focusTechID
            else
                set obj.techtree            = 0
            endif
        endif
        if not IsFrameUseable(trigPlayer) then
            return
        endif
        call DrawUIFromPlayerData(trigPlayer, obj)
    endmethod
    static method onChoiceArrowClick takes nothing returns nothing
        local framehandle zabutton  = BlzGetTriggerFrame()
        local integer i             = CustomRaceInterface.getChoiceArrowID(zabutton)
        local player  trigPlayer    = GetTriggerPlayer()
        local integer incr          = 1
        call PlaySoundForPlayer(GenerateClickSound(), trigPlayer)
        if BlzBitAnd(i, 1) == 0 then
            set incr    = -1
        endif
        if FrameInterpolation.localPlayer == trigPlayer then
            call CustomRaceInterface.setSliderValue(CustomRaceInterface.getSliderValue() + incr)
        endif
    endmethod
    static method onTechtreeArrowClick takes nothing returns nothing
        local framehandle zabutton      = BlzGetTriggerFrame()
        local integer i                 = CustomRaceInterface.getTechtreeArrowID(zabutton)
        local integer techChunk         = ((i - 1) / CustomRaceUI_GetTechtreeChunkCount()) + 1
        local integer inc               = CustomRaceUI_GetTechtreeIconColumnMax()
        local integer newBase           = 0
        local player  trigPlayer        = GetTriggerPlayer()
        local CustomRacePSelection obj  = CRPSelection[trigPlayer]
        //  If the direction is up, decrease the base choice instead.
        if BlzBitAnd(i, 1) != 0 then
            set inc = -inc
        endif
        set newBase = IMaxBJ(obj.getBaseTechID(techChunk) + inc, 0)
        if newBase == obj.getBaseTechID(techChunk) then
            return
        endif
        call obj.setBaseTechID(techChunk, newBase)
        if obj.techtree != 0 then
            set obj.techtree        = obj.techtree - inc
            //  The techtree icon previously highlighted is out of bounds
            if (obj.techtree <= 0) or (obj.techtree > CustomRaceInterface.iconsPerChunk) then
                set obj.techtree            = 0
                set obj.focusTechID         = 0
                set obj.focusTechtree       = 0
                set obj.focusTechtreeStack  = 0
            else
                set obj.focusTechID         = obj.techtree
            endif
        endif
        if not IsFrameUseable(trigPlayer) then
            return
        endif
        call DrawUIFromPlayerData(trigPlayer, obj)
    endmethod
    static method onConfirmButtonClick takes nothing returns nothing
        local framehandle zabutton      = BlzGetTriggerFrame()
        local player  trigPlayer        = GetTriggerPlayer()
        local CustomRacePSelection obj  = CRPSelection[trigPlayer]
        local integer finalChoice       = 0
        local integer i                 = 0
        //  obj.focusFactionStack can only be equal to 2
        //  if a choice button was already selected.
        if obj.faction == 0 then
            call PlaySoundForPlayer(GenerateWarningSound(), trigPlayer)
            return
        endif
        if not IsFrameUseable(trigPlayer) then
            return
        endif
        set finalChoice             = obj.faction + obj.baseChoice
        set obj.focusFaction        = 0
        set obj.faction             = 0
        set obj.focusFactionStack   = 0
        set obj.techtree            = 0
        set obj.focusTechtree       = 0
        set obj.focusTechID         = 0
        set obj.focusTechtreeStack  = 0
        loop
            exitwhen i > CustomRaceUI_GetTechtreeChunkCount()
            call obj.setBaseTechID(i, 0)
            set i = i + 1
        endloop
        call DrawUIFromPlayerData(trigPlayer, obj)
        set obj.faction             = finalChoice
        call CustomRacePSelection.removeChoicedPlayer(trigPlayer)
        call CustomRacePSelection.addUnchoicedPlayer(trigPlayer)
        call FrameInterpolation[trigPlayer].stop(MODE_BAR_UPDATE)
        call HideCustomFrame(trigPlayer)
        call CustomRaceObserverUI_RenderFrame()
        if CustomRacePSelection.choicedPlayerSize < 1 then
            call PauseTimer(finalizer)
            call DestroyTimer(finalizer)
            call thistype.finalize()
            call CustomRaceObserverUI_UnrenderFrame()
        endif
    endmethod
    //  ==========================================================================  //
    //                              Scroll Events                                   //
    //  ==========================================================================  //
    static method onSliderValueChange takes nothing returns nothing
        local integer value             = R2I(BlzGetTriggerFrameValue() + 0.01)
        local integer maxBase           = 0
        local integer newBase           = 0
        local integer oldBase           = 0
        local player  trigPlayer        = GetTriggerPlayer()
        local CustomRacePSelection obj  = CRPSelection[trigPlayer]
        set maxBase                     = IMaxBJ(CustomRace.getRaceFactionCount(GetPlayerRace(trigPlayer)) - CustomRaceUI_GetMaxDisplayChoices(), /*
                                              */ 0)
        set newBase                     = maxBase - value
        if obj.baseChoice == newBase then
            return
        endif
        set oldBase                     = obj.baseChoice
        set obj.baseChoice              = newBase
        if FrameInterpolation.localPlayer == trigPlayer then
            call BlzFrameSetFocus(CustomRaceInterface.getChoiceButton(obj.faction), false)
        endif
        if obj.faction != 0 then
            set obj.focusFaction            = obj.focusFaction + oldBase - obj.baseChoice
            set obj.faction                 = obj.focusFaction
            //  If the faction in focus is out of the list of choices displayed,
            //  clear out.
            if (obj.focusFaction <= 0) or (obj.focusFaction > CustomRaceUI_GetMaxDisplayChoices()) then
                set obj.focusFaction        = 0
                set obj.faction             = 0
                set obj.focusFactionStack   = 0

                set obj.focusTechtree       = 0
                set obj.focusTechID         = 0
                set obj.techtree            = 0
                set obj.focusTechtreeStack  = 0
            endif
        endif
        if not IsFrameUseable(trigPlayer) then
            return
        endif
        call DrawUIFromPlayerData(trigPlayer, obj)
    endmethod
    static method onSliderDetectWheel takes nothing returns nothing
        local real value    = BlzGetTriggerFrameValue()
        if value > 0 then
            call CustomRaceInterface.setSliderValue(CustomRaceInterface.getSliderValue() + 1)
        else
            call CustomRaceInterface.setSliderValue(CustomRaceInterface.getSliderValue() - 1)
        endif
    endmethod
    //  ==========================================================================  //
    //                              Abandon Event                                   //
    //  ==========================================================================  //
    static method onPlayerAbandon takes nothing returns nothing
        local player  trigPlayer        = GetTriggerPlayer()
        call FrameInterpolation[trigPlayer].stop(MODE_BAR_UPDATE)
        call CustomRacePSelection.removeChoicedPlayer(trigPlayer)
        call CustomRacePSelection.removeUnchoicedPlayer(trigPlayer)
        if CustomRacePSelection.choicedPlayerSize < 1 then
            call PauseTimer(finalizer)
            call DestroyTimer(finalizer)
            call thistype.finalize()
            call CustomRaceObserverUI_UnrenderFrame()
        else
            call CustomRaceObserverUI_RenderFrame()
        endif
        call DisplayTimedTextToPlayer(FrameInterpolation.localPlayer, 0.0, 0.0, 20.0, /*
                                   */ GetPlayerName(trigPlayer) + " has abandoned the game.")
    endmethod

    private static method init takes nothing returns nothing
        set onDefaultFinalize   = function thistype.onExpireFinalize
    endmethod
    implement Init
endstruct

private function PrepHoverEvents takes nothing returns nothing
    local trigger enterTrig = CreateTrigger()
    local trigger leaveTrig = CreateTrigger()
    local integer i         = 1
    local integer j         = 1
    //  Add events to the choice buttons
    loop
        exitwhen i > CustomRaceUI_GetMaxDisplayChoices()
        call BlzTriggerRegisterFrameEvent(enterTrig, CustomRaceInterface.getChoiceButton(i), /*
                                        */FRAMEEVENT_MOUSE_ENTER)
        call BlzTriggerRegisterFrameEvent(leaveTrig, CustomRaceInterface.getChoiceButton(i), /*
                                        */FRAMEEVENT_MOUSE_LEAVE)
        set i = i + 1
    endloop
    call TriggerAddAction(enterTrig, function UIFrameEvents.onChoiceButtonEnter)
    call TriggerAddAction(leaveTrig, function UIFrameEvents.onChoiceButtonLeave)
    //  Add events to the techtree buttons
    set enterTrig   = CreateTrigger()
    set leaveTrig   = CreateTrigger()
    set i           = 1
    set j           = CustomRaceUI_GetTechtreeChunkCount()*CustomRaceUI_GetTechtreeIconColumnMax()
    set j           = j*CustomRaceUI_GetTechtreeIconRowMax()
    loop
        exitwhen i > j
        call BlzTriggerRegisterFrameEvent(enterTrig, CustomRaceInterface.getTechtreeIconRaw(i), /*
                                        */FRAMEEVENT_MOUSE_ENTER)
        call BlzTriggerRegisterFrameEvent(leaveTrig, CustomRaceInterface.getTechtreeIconRaw(i), /*
                                        */FRAMEEVENT_MOUSE_LEAVE)
        set i = i + 1
    endloop
    call TriggerAddAction(enterTrig, function UIFrameEvents.onTechtreeIconEnter)
    call TriggerAddAction(leaveTrig, function UIFrameEvents.onTechtreeIconLeave)
endfunction
private function PrepClickEvents takes nothing returns nothing
    local trigger clickTrig = CreateTrigger()
    local integer i         = 1
    local integer j         = 1
    //  Add events to the choice buttons
    loop
        exitwhen i > CustomRaceUI_GetMaxDisplayChoices()
        call BlzTriggerRegisterFrameEvent(clickTrig, CustomRaceInterface.getChoiceButton(i), /*
                                        */FRAMEEVENT_CONTROL_CLICK)
        set i = i + 1
    endloop
    call TriggerAddAction(clickTrig, function UIFrameEvents.onChoiceButtonClick)
    //  Add events to the techtree buttons
    set clickTrig   = CreateTrigger()
    set i           = 1
    set j           = CustomRaceUI_GetTechtreeChunkCount()*CustomRaceUI_GetTechtreeIconColumnMax()
    set j           = j*CustomRaceUI_GetTechtreeIconRowMax()
    loop
        exitwhen i > j
        call BlzTriggerRegisterFrameEvent(clickTrig, CustomRaceInterface.getTechtreeIconRaw(i), /*
                                        */FRAMEEVENT_CONTROL_CLICK)
        set i = i + 1
    endloop
    call TriggerAddAction(clickTrig, function UIFrameEvents.onTechtreeIconClick)
    //  Add events to the choice arrows
    set clickTrig   = CreateTrigger()
    call BlzTriggerRegisterFrameEvent(clickTrig, CustomRaceInterface.getChoiceArrow(true), /*
                                   */ FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(clickTrig, CustomRaceInterface.getChoiceArrow(false), /*
                                   */ FRAMEEVENT_CONTROL_CLICK)
    call TriggerAddAction(clickTrig, function UIFrameEvents.onChoiceArrowClick)
    //  Add events to the techtree arrows
    set clickTrig   = CreateTrigger()
    set i           = 1
    set j           = CustomRaceUI_GetTechtreeChunkCount()
    loop
        exitwhen i > j
        call BlzTriggerRegisterFrameEvent(clickTrig, CustomRaceInterface.getTechtreeArrow(i, true), /*
                                        */FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(clickTrig, CustomRaceInterface.getTechtreeArrow(i, false), /*
                                        */FRAMEEVENT_CONTROL_CLICK)
        set i = i + 1
    endloop
    call TriggerAddAction(clickTrig, function UIFrameEvents.onTechtreeArrowClick)
    //  Add the final event to the confirm button.
    set clickTrig   = CreateTrigger()
    call BlzTriggerRegisterFrameEvent(clickTrig, CustomRaceInterface.confirmFrame, /*
                                    */FRAMEEVENT_CONTROL_CLICK)
    call TriggerAddAction(clickTrig, function UIFrameEvents.onConfirmButtonClick)
endfunction
private function PrepScrollEvents takes nothing returns nothing
    local trigger trig  = CreateTrigger()
    call BlzTriggerRegisterFrameEvent(trig, CustomRaceInterface.slider, /*
                                    */FRAMEEVENT_SLIDER_VALUE_CHANGED)
    call TriggerAddAction(trig, function UIFrameEvents.onSliderValueChange)
    set trig    = CreateTrigger()
    call BlzTriggerRegisterFrameEvent(trig, CustomRaceInterface.slider, /*
                                    */FRAMEEVENT_MOUSE_WHEEL)
    call TriggerAddAction(trig, function UIFrameEvents.onSliderDetectWheel)
endfunction
private function PrepAbandonEvent takes nothing returns nothing
    local integer i = 1
    loop
        exitwhen i > CustomRacePSelection.choicedPlayerSize
        call TriggerRegisterPlayerEvent(UIFrameEvents.abandonTrig, CustomRacePSelection.choicedPlayers[i], /*
                                     */ EVENT_PLAYER_LEAVE)
        set i = i + 1
    endloop
    set i   = 1
    loop
        exitwhen i > CustomRacePSelection.unchoicedPlayerSize
        call TriggerRegisterPlayerEvent(UIFrameEvents.abandonTrig, CustomRacePSelection.unchoicedPlayers[i], /*
                                     */ EVENT_PLAYER_LEAVE)
        set i = i + 1
    endloop
    call TriggerAddAction(UIFrameEvents.abandonTrig, function UIFrameEvents.onPlayerAbandon)
endfunction
private function PrepEvents takes nothing returns nothing
    call PrepHoverEvents()
    call PrepClickEvents()
    call PrepScrollEvents()
    call PrepAbandonEvent()
endfunction
//  ==========================================================================  //

//  ==========================================================================  //
private function FillWithPlayerData takes player whichPlayer returns nothing
    local CustomRacePSelection obj  = CRPSelection[whichPlayer]
    local integer maxSteps          = CustomRace.getRaceFactionCount(GetPlayerRace(whichPlayer))
    set maxSteps                    = IMaxBJ(maxSteps - CustomRaceUI_GetMaxDisplayChoices(), 0)
    if (maxSteps != 0) and (FrameInterpolation.localPlayer == whichPlayer) then
        call CustomRaceInterface.setSliderMaxValue(maxSteps)
    endif
    call DrawUIFromPlayerData(whichPlayer, obj)
endfunction
private function PopulateUI takes nothing returns nothing
    local integer i = 1
    loop
        exitwhen i > CustomRacePSelection.choicedPlayerSize
        call FillWithPlayerData(CustomRacePSelection.choicedPlayers[i])
        set i = i + 1
    endloop
    //  All players don't have a faction choice, proceed with game
    //  as normal
    if CustomRacePSelection.choicedPlayerSize < 1 then
        call UIFrameEvents.onFinalizeEnd()
    else
        call CustomRaceObserverUI_RenderFrame()
    endif
endfunction
//  ==========================================================================  //

public function Initialization takes nothing returns nothing
    call CustomRacePSelection.init()
    call CustomRaceMatch_MeleeInitialization()
    call PrepUI()
    call PopulateUI()
    call PrepEvents()
endfunction

endlibrary
