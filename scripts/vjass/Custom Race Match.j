//$ noimport
library CustomRaceMatch requires /*

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

    ------------------------------
    */  optional Init           /*
    ------------------------------

*/

globals
    private constant boolean FOGGED_START                   = false
    private constant boolean USE_EXTRA_TICK                 = true
    public  constant boolean APPLY_TIMER_IN_SINGLE_PLAYER   = false
    
    private constant integer GAME_START_TICKS               = 3
    private constant integer EXTRA_TICK_FOR_START           = 1
    private constant real    TICK_INTERVAL                  = 1.0
    private constant real    DISPLAY_LIFETIME               = 0.80
    private constant real    DISPLAY_INTERVAL               = 1.0 / 100.0
endglobals

//  =============================================================================   //
private function ClearMusicPlaylist takes nothing returns nothing
    //  Observers can't play any faction playlist,
    //  so return at this point. Comment later
    //  if this causes desyncs.
    if IsPlayerObserver(GetLocalPlayer()) then
        return
    endif
    call ClearMapMusic()
    call StopMusic(false)
endfunction
//  =============================================================================   //

//  =============================================================================   //
//  In previous versions, visibility was actually affected.
//  In modern versions, visibility is kept intact and only
//  the time of day is affected.
//  =============================================================================   //
private function StartingVisibility takes nothing returns nothing
    call SetFloatGameState(GAME_STATE_TIME_OF_DAY, bj_MELEE_STARTING_TOD)
    call SuspendTimeOfDay(true)
    static if FOGGED_START then
        call FogMaskEnable(true)
        call FogEnable(true)
    endif
endfunction
//  =============================================================================   //

//  =============================================================================   //
private function StartingHeroLimit takes nothing returns nothing
    local integer index         = 0
    local integer i             = 1
    local integer maxHeroIndex  = CustomRace.getGlobalHeroMaxIndex()
    local player whichPlayer
    loop
        exitwhen index > bj_MAX_PLAYERS
        set whichPlayer = Player(index)
        set i           = 1
        call SetPlayerTechMaxAllowed(whichPlayer, 'HERO', bj_MELEE_HERO_LIMIT)
        loop
            exitwhen i > maxHeroIndex
            call SetPlayerTechMaxAllowed(whichPlayer, CustomRace.getGlobalHero(i), /*
                                      */ bj_MELEE_HERO_TYPE_LIMIT)
            set i   = i + 1
        endloop
        set index   = index + 1
    endloop
    set whichPlayer             = null
endfunction
//  =============================================================================   //

//  =============================================================================   //
private function GrantItem takes unit hero returns nothing
    if IsUnitType(hero, UNIT_TYPE_HERO) then
        call MeleeGrantItemsToHero(hero)
    endif
endfunction
private function OnNeutralHeroHired takes nothing returns nothing
    call GrantItem(GetSoldUnit())
endfunction
private function OnTrainedHeroFinish takes nothing returns nothing
    call GrantItem(GetTrainedUnit())
endfunction
private function GrantHeroItems takes nothing returns nothing
    local integer index         = 0
    local trigger trig          = CreateTrigger()
    local player whichPlayer    = null
    call TriggerAddAction(trig, function OnTrainedHeroFinish)

    loop
        exitwhen index > bj_MAX_PLAYER_SLOTS
        // Initialize the twinked hero counts.
        set bj_meleeTwinkedHeroes[index]    = 0
        set whichPlayer                     = Player(index)
        
        // Register for an event whenever a hero is trained, so that we can give
        // him/her their starting items. Exclude
        if (index < bj_MAX_PLAYERS) and CustomRaceMatchConditions_IsPlayerActive(whichPlayer) then
            call TriggerRegisterPlayerUnitEvent(trig, whichPlayer, /*
                                             */ EVENT_PLAYER_UNIT_TRAIN_FINISH, null)
        endif
        set index                           = index + 1
    endloop
    set whichPlayer = null
    // Register for an event whenever a neutral hero is hired, so that we
    // can give him/her their starting items.
    set trig        = CreateTrigger()
    call TriggerRegisterPlayerUnitEvent(trig, Player(PLAYER_NEUTRAL_PASSIVE), /*
                                     */ EVENT_PLAYER_UNIT_SELL, null)
    call TriggerAddAction(trig, function OnNeutralHeroHired)
    set trig    = null

    // Flag that we are giving starting items to heroes, so that the melee
    // starting units code can create them as necessary.
    set bj_meleeGrantHeroItems = true
endfunction
//  =============================================================================   //

//  =============================================================================   //
private function StartingResources takes nothing returns nothing
    local integer index
    local player  whichPlayer
    local version v
    local integer startingGold      = bj_MELEE_STARTING_GOLD_V1
    local integer startingLumber    = bj_MELEE_STARTING_LUMBER_V1

    set v = VersionGet()
    if (v == VERSION_REIGN_OF_CHAOS) then
        set startingGold = bj_MELEE_STARTING_GOLD_V0
        set startingLumber = bj_MELEE_STARTING_LUMBER_V0
    endif
    set v = null

    // Set each player's starting resources.
    set index = 0
    loop
        set whichPlayer = Player(index)
        if CustomRaceMatchConditions_IsPlayerActive(whichPlayer) then
            call SetPlayerState(whichPlayer, PLAYER_STATE_RESOURCE_GOLD, startingGold)
            call SetPlayerState(whichPlayer, PLAYER_STATE_RESOURCE_LUMBER, startingLumber)
        endif

        set index = index + 1
        exitwhen index == bj_MAX_PLAYERS
    endloop
endfunction
//  =============================================================================   //

//  =============================================================================   //
private function RemoveNearbyUnits takes real x, real y, real radius returns nothing
    local integer i         = 0
    local integer owner     = 0
    local integer size      = 0
    local group nearbyUnits = CreateGroup()
    local unit  enumUnit

    call GroupEnumUnitsInRange(nearbyUnits, x, y, radius, null)
    set size        = BlzGroupGetSize(nearbyUnits)
    loop
        exitwhen i >= size
        set enumUnit    = BlzGroupUnitAt(nearbyUnits, i)
        set owner       = GetPlayerId(GetOwningPlayer(enumUnit))
        if (owner == PLAYER_NEUTRAL_AGGRESSIVE) or /*
        */ ((owner == PLAYER_NEUTRAL_PASSIVE) and /*
        */  (not IsUnitType(enumUnit, UNIT_TYPE_STRUCTURE))) then
            // Remove any Neutral Hostile units or
            // Neutral Passive units (not structures) from the area.
            call RemoveUnit(enumUnit)
        endif
        set i   = i + 1
    endloop
    call DestroyGroup(nearbyUnits)
    set enumUnit    = null
    set nearbyUnits = null
endfunction
private function ClearExcessUnits takes nothing returns nothing
    local integer index         = 0
    local real    locX
    local real    locY
    local player  indexPlayer

    loop
        set indexPlayer = Player(index)
        // If the player slot is being used, clear any nearby creeps.
        if CustomRaceMatchConditions_IsPlayerActive(indexPlayer) then
            set locX = GetStartLocationX(GetPlayerStartLocation(indexPlayer))
            set locY = GetStartLocationY(GetPlayerStartLocation(indexPlayer))
            call RemoveNearbyUnits(locX, locY, bj_MELEE_CLEAR_UNITS_RADIUS)
        endif
        set index = index + 1
        exitwhen index == bj_MAX_PLAYERS
    endloop
    set indexPlayer     = null
endfunction
//  =============================================================================   //

//  =============================================================================   //
private function DefineVictoryDefeat takes nothing returns nothing
    //  Unravelling this function will open a can of worms
    //  the likes which would not likely be appreciated.
    //  Leave it as it is, and make changes in a separate
    //  library specifically for this function.
    call CustomRaceMatchConditions_DefineVictoryDefeat()
endfunction
//  =============================================================================   //

//  =============================================================================   //
private function OnStartCheckAlliance takes nothing returns nothing
    local timer whichTimer  = GetExpiredTimer()
    call PauseTimer(whichTimer)
    call DestroyTimer(whichTimer)
    set whichTimer          = null
    call CustomRaceMatchConditions_OnAllianceChange()
endfunction
public  function TestVictoryDefeat takes nothing returns nothing
    // Test for victory / defeat at startup, in case the user has already won / lost.
    // Allow for a short time to pass first, so that the map can finish loading.
    call TimerStart(CreateTimer(), 2.0, false, function OnStartCheckAlliance)
endfunction
//  =============================================================================   //

//  =============================================================================   //
globals
    private integer  tempStart          = 0
    private location tempStartLoc       = null
    private player   tempStartPlayer    = null
endglobals

public  function OnStartGetPlayer takes nothing returns player
    return tempStartPlayer
endfunction
public  function OnStartGetLoc takes nothing returns location
    return tempStartLoc
endfunction
private function StartingUnits takes nothing returns nothing
    local integer  index            = 1
    local CustomRacePSelection obj  = 0
    local CustomRace faction        = 0
    local player   indexPlayer
    local race     pRace

    call Preloader( "scripts\\SharedMelee.pld" )
    loop
        exitwhen index > CustomRacePSelection.unchoicedPlayerSize
        set indexPlayer     = CustomRacePSelection.unchoicedPlayers[index]
        set tempStartPlayer = indexPlayer
        set tempStart       = GetPlayerStartLocation(indexPlayer)
        set tempStartLoc    = GetStartLocationLoc(tempStart)
        set pRace           = GetPlayerRace(indexPlayer)
        set obj             = CRPSelection[indexPlayer]
        set faction         = CustomRace.getRaceFaction(pRace, obj.faction)
        
        call faction.execSetup()
        if GetPlayerController(indexPlayer) == MAP_CONTROL_COMPUTER then
            call faction.execSetupAI()
        endif
        call RemoveLocation(tempStartLoc)
        set index = index + 1
    endloop
    set pRace           = null
    //  Do NOT make these usable afterwards!
    set tempStartPlayer = null
    set tempStart       = 0
    set tempStartLoc    = null
endfunction
//  =============================================================================   //

//  =============================================================================   //
private struct FrameInterpolation
    private static  constant real FRAME_SCALE       = 10.0
    private static  constant real FRAME_ENDSCALE    = 2.0
    private static  constant real START_X           = 0.40
    private static  constant real END_X             = 0.40
    private static  constant real START_Y           = 0.45
    private static  constant real END_Y             = 0.25
    private static  constant framepointtype POINT   = FRAMEPOINT_CENTER
    
    private static  thistype array objectList
    private static  integer objectCurIndex          = 0
    private static  timer   interpolator            = CreateTimer()

    private string  message
    private integer maxTicks
    private integer ticks
    private framehandle frame

    private static method alphaResponse takes real x returns real
        set x   = x - 0.5
        return -16.0*(x*x*x*x) + 1.0
    endmethod
    private static method slideResponse takes real x returns real
        set x   = x - 0.5
        return -4.0*(x*x*x) + 0.5
    endmethod
    private static method scaleResponse takes real x returns real
        return -(x*x*x*x*x*x) + 1.0
    endmethod

    private method destroy takes nothing returns nothing
        set this.ticks      = 0
        set this.maxTicks   = 0
        call BlzFrameSetVisible(this.frame, false)
        call BlzDestroyFrame(this.frame)
        call this.deallocate()
    endmethod

    private static method onUpdate takes nothing returns nothing
        local integer i     = 1
        local thistype this = 0
        local real ratio    = 0.0
        local real resp     = 0.0
        local real cx       = 0.0
        local real cy       = 0.0
        local real scale    = 0.0
        loop
            exitwhen i > objectCurIndex
            set this        = objectList[i]
            set this.ticks  = this.ticks + 1
            set ratio       = I2R(this.ticks) / I2R(this.maxTicks)
            call BlzFrameSetAlpha(this.frame, R2I(255.0*thistype.alphaResponse(ratio)))

            set resp        = slideResponse(ratio)
            set cx          = START_X*resp + END_X*(1-resp)
            set cy          = START_Y*resp + END_Y*(1-resp)

            set resp        = scaleResponse(ratio)
            set scale       = FRAME_SCALE*resp + FRAME_ENDSCALE*(1-resp)
            call BlzFrameSetAbsPoint(this.frame, POINT, cx, cy)
            call BlzFrameSetScale(this.frame, scale)

            if this.ticks >= this.maxTicks then
                set objectList[i]   = objectList[objectCurIndex]
                set objectCurIndex  = objectCurIndex - 1
                set i               = i - 1
                call this.destroy()
            endif
            set i = i + 1
        endloop
        if objectCurIndex < 1 then
            call PauseTimer(interpolator)
        endif
    endmethod
    private static method insert takes thistype this returns nothing
        set objectCurIndex              = objectCurIndex + 1
        set objectList[objectCurIndex]  = this
        if objectCurIndex == 1 then
            call TimerStart(interpolator, DISPLAY_INTERVAL, true, function thistype.onUpdate)
        endif
    endmethod
    static method request takes string msg, real lifetime returns nothing
        local thistype this = thistype.allocate()
        set this.message    = msg
        set this.maxTicks   = R2I(lifetime / DISPLAY_INTERVAL + 0.01)
        set this.ticks      = 0
        set this.frame      = BlzCreateFrameByType("TEXT", "CustomRaceMatchDisplayText", /*
                                                */ BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), /*
                                                */ "", integer(this))
        call BlzFrameSetText(this.frame, message)
        call BlzFrameSetScale(this.frame, FRAME_SCALE)
        call BlzFrameSetAlpha(this.frame, 0)
        call BlzFrameSetAbsPoint(this.frame, POINT, START_X, START_Y)
        call thistype.insert(this)
    endmethod
endstruct
private function DisplayToWorld takes string msg, real lifetime returns nothing
    call FrameInterpolation.request(msg, lifetime)
endfunction
//  =============================================================================   //

//  =============================================================================   //
globals
    private integer beginTick   = 0
    private integer extraTick   = 0
    private group   tickGroup   = null
    private sound   tempSound   = null
endglobals
private function GenerateTickSound takes nothing returns sound
    set tempSound   = CreateSound( "Sound\\Interface\\BattleNetTick.wav", false, false, false, 10, 10, "" )
    call SetSoundParamsFromLabel( tempSound, "ChatroomTimerTick" )
    call SetSoundDuration( tempSound, 476 )
    return tempSound
endfunction
private function GenerateHornSound takes nothing returns sound
    set tempSound   = CreateSound( "Sound\\Ambient\\DoodadEffects\\TheHornOfCenarius.wav", false, false, false, 10, 10, "DefaultEAXON" )
    call SetSoundParamsFromLabel( tempSound, "HornOfCenariusSound" )
    call SetSoundDuration( tempSound, 12120 )
    return tempSound
endfunction
private function PlaySoundForPlayer takes sound snd, player p returns nothing
    if GetLocalPlayer() != p then
        call SetSoundVolume(snd, 0)
    endif
    call StartSound(snd)
    call KillSoundWhenDone(snd)
endfunction
//  =============================================================================   //

//  =============================================================================   //
private function SetupPlaylist takes nothing returns nothing
    local player whichPlayer        = GetLocalPlayer()
    local CustomRacePSelection obj  = CRPSelection[whichPlayer]
    local CustomRace faction        = CustomRace.getRaceFaction(GetPlayerRace(whichPlayer), obj.faction)
    if faction == 0 then
        return
    endif
    call SetMapMusic(faction.playlist, true, 0)
    call PlayMusic(faction.playlist)
    set whichPlayer                 = null
endfunction
private function ResetVisuals takes nothing returns nothing
    call EnableDragSelect(true, true)
    call EnablePreSelect(true, true)
    call EnableSelect(true, true)
    call EnableUserControl(true)
    call EnableUserUI(true)
    call SuspendTimeOfDay(false)
endfunction
private function MatchTickDown takes nothing returns nothing
    local integer i         = 0
    local integer size      = 0
    local timer expTimer
    set beginTick           = beginTick - 1
    if beginTick > 0 then
        call StartSound(GenerateTickSound())
        call KillSoundWhenDone(tempSound)
        call DisplayToWorld(I2S(beginTick), DISPLAY_LIFETIME)
        return
    endif
    set extraTick       = extraTick - 1
    if extraTick > 0 then
        return
    endif
    call StartSound(GenerateHornSound())
    call KillSoundWhenDone(tempSound)
    call DisplayToWorld("|cffff4040Start!|r", 1.20)
    
    set expTimer            = GetExpiredTimer()
    call PauseTimer(expTimer)
    call DestroyTimer(expTimer)
    set expTimer            = null
    call TestVictoryDefeat()
    call ResetVisuals()
    call SetupPlaylist()

    set size            = BlzGroupGetSize(tickGroup)
    loop
        exitwhen i >= size
        call PauseUnit(BlzGroupUnitAt(tickGroup, i), false)
        set i = i + 1
    endloop
endfunction
private function SetupVisuals takes nothing returns nothing
    local real zdist    = GetCameraField(CAMERA_FIELD_TARGET_DISTANCE)
    local real ndist    = zdist + 1250.0
    if IsPlayerInForce(GetLocalPlayer(), CustomRaceForce.activePlayers) then
        call SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, ndist, 0.00)
        call SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, zdist, 0.00)
    endif
    call EnableDragSelect(false, false)
    call EnablePreSelect(false, false)
    call EnableSelect(false, false)
    call EnableUserControl(false)
    call EnableUserUI(false)
endfunction
private function BeginMatch takes nothing returns nothing
    local rect world    = GetWorldBounds()
    local integer i     = 0
    local integer size  = 0
    set tickGroup       = CreateGroup()
    set beginTick       = GAME_START_TICKS + 1
    if USE_EXTRA_TICK then
        set extraTick   = EXTRA_TICK_FOR_START
    endif
    call TimerStart(CreateTimer(), TICK_INTERVAL, true, function MatchTickDown)
    call SetupVisuals()
    call GroupEnumUnitsInRect(tickGroup, world, null)
    set size            = BlzGroupGetSize(tickGroup)
    loop
        exitwhen i >= size
        call PauseUnit(BlzGroupUnitAt(tickGroup, i), true)
        set i = i + 1
    endloop
    //  Cleaned up, thanks to Jass Script Helper.
    call RemoveRect(world)
    set world           = null
endfunction
//  =============================================================================   //

//  =============================================================================   //
public function MeleeInitialization takes nothing returns nothing
    call ClearMusicPlaylist()
    call StartingVisibility()
    call StartingHeroLimit()
    call GrantHeroItems()
    call StartingResources()
    call ClearExcessUnits()
endfunction

public function MeleeInitializationFinish takes nothing returns nothing
    call DefineVictoryDefeat()
    call StartingUnits()
    call BeginMatch()
endfunction

endlibrary
