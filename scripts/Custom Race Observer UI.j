//$ noimport
library CustomRaceObserverUI requires /*

    --------------------------
    */  CustomRaceCore,     /*
    --------------------------

    ----------------------
    */  CustomRaceUI,   /*
    ----------------------

    ------------------------------
    */  CustomRacePSelection,   /*
    ------------------------------

    --------------
    */  Init,   /*
    --------------

    ------------------------------
    */  optional FrameLoader    /*
    ------------------------------
        - By Tasyen
        - You can find it in most of Tasyen's UI resources in the Spells section.

    ------------------
    */  GameStatus  /*
    ------------------
        - By TriggerHappy
        - link: https://www.hiveworkshop.com/threads/gamestatus-replay-detection.293176/

     -----------------------------------------------------
    |
    |   CustomRaceObserverUI
    |
    |-----------------------------------------------------
    |
    |   A library that handles displaying the list of players
    |   who have yet to select a faction. Hidden for actual
    |   players. Can be seen by observers and in replays.
    |
     -----------------------------------------------------

*/

globals
    private player localPlayer      = null
    private boolean repVarAssigned  = false
    private boolean isReplay        = false
endglobals

//  This only applies to players. Observers will always see the
//  faction choice.
private constant function DisplayPlayerFactionChoice takes nothing returns boolean
    return false
endfunction
private constant function GetObserverFrameHeight takes nothing returns real
    return 0.28
endfunction
private constant function GetObserverFrameWidth takes nothing returns real
    return 0.28
endfunction
private constant function GetObserverFrameCenterX takes nothing returns real
    return 0.40
endfunction
private constant function GetObserverFrameCenterY takes nothing returns real
    return 0.35
endfunction

private constant function GetContainerWidthOffset takes nothing returns real
    return 0.06
endfunction
private constant function GetContainerHeightOffset takes nothing returns real
    return 0.10
endfunction
private constant function GetContainerFramePoint takes nothing returns framepointtype
    return FRAMEPOINT_BOTTOM
endfunction
private constant function GetContainerOffsetX takes nothing returns real
    return 0.00
endfunction
private constant function GetContainerOffsetY takes nothing returns real
    return 0.01
endfunction

private constant function GetPlayerTextGuideHeight takes nothing returns real
    return 0.03
endfunction
private constant function GetPlayerTextOffsetX takes nothing returns real
    return 0.00
endfunction
private constant function GetPlayerTextOffsetY takes nothing returns real
    return -0.0075
endfunction

private constant function GetPlayerTextGuidePlayerNameOffsetX takes nothing returns real
    return 0.04
endfunction
private constant function GetPlayerTextGuidePlayerSelectionOffsetX takes nothing returns real
    return 0.08
endfunction

private constant function GetSliderWidth takes nothing returns real
    return 0.012
endfunction
private constant function GetSliderOffsetX takes nothing returns real
    return -0.006
endfunction
private constant function GetSliderOffsetY takes nothing returns real
    return 0.0
endfunction

private constant function GetPlayerFrameCount takes nothing returns integer
    return 8
endfunction
private constant function GetPlayerFrameWidthOffset takes nothing returns real
    return 0.006
endfunction
private constant function GetPlayerFrameOffsetX takes nothing returns real
    return 0.003
endfunction
private constant function GetPlayerFrameOffsetY takes nothing returns real
    return 0.0
endfunction

private function GetFrameIndex takes framehandle whichFrame returns integer
    return ModuloInteger(GetHandleId(whichFrame) - 0x1000000, 0x8000)
endfunction

struct CustomRaceObserverUI extends array
    static   integer maxValue                           = 1

    readonly static integer array basePlayerIndex
    readonly static framehandle main                    = null
    readonly static framehandle playerContainer         = null
    readonly static framehandle playerTextGuide         = null
    readonly static framehandle playerPanelSlider       = null
    readonly static framehandle array playerTextParams

    readonly static framehandle array playerFrame
    readonly static framehandle array playerFrameBG
    readonly static framehandle array playerFrameHighlight
    readonly static framehandle array playerFrameName
    readonly static framehandle array playerFrameFaction
    private  static integer array playerFrameID

    private static method initMainFrames takes nothing returns nothing
        set main                = BlzCreateFrameByType("BACKDROP", "CustomRaceObserverMainFrame", /*
                                        */ BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), /*
                                        */ "EscMenuButtonBackdropTemplate", 0)
        call BlzFrameSetSize(main, GetObserverFrameWidth(), GetObserverFrameHeight())
        call BlzFrameSetAbsPoint(main, FRAMEPOINT_CENTER, GetObserverFrameCenterX(), /*
                              */ GetObserverFrameCenterY())
        
        set playerContainer     = BlzCreateFrameByType("BACKDROP", "CustomRaceObserverContainer", /*
                                                */ main, "EscMenuControlBackdropTemplate", 0)
        call BlzFrameSetSize(playerContainer, BlzFrameGetWidth(main) - GetContainerWidthOffset() / 2.0, /*
                          */ BlzFrameGetWidth(main) - GetContainerHeightOffset())
        call BlzFrameSetPoint(playerContainer, GetContainerFramePoint(), main, FRAMEPOINT_BOTTOM, /*
                           */ GetContainerOffsetX(), GetContainerOffsetY())

        set playerTextGuide     = BlzCreateFrameByType("BACKDROP", "CustomRaceObserverTextGuide", /*
                                                */ main, "EscMenuControlBackdropTemplate", 0)
        call BlzFrameSetSize(playerTextGuide, BlzFrameGetWidth(playerContainer), /*
                          */ GetPlayerTextGuideHeight())
        call BlzFrameSetPoint(playerTextGuide, FRAMEPOINT_BOTTOM, playerContainer, /*
                           */ FRAMEPOINT_TOP, GetPlayerTextOffsetX(), GetPlayerTextOffsetY())

        set playerPanelSlider   = BlzCreateFrameByType("SLIDER", "CustomRaceObserverPlayerPanelSlider", /*
                                                    */ playerContainer, "EscMenuSliderTemplate", 0)
        call BlzFrameSetPoint(playerPanelSlider, FRAMEPOINT_LEFT, playerContainer, FRAMEPOINT_RIGHT, /*
                           */ GetSliderOffsetX(), GetSliderOffsetY())
        call BlzFrameSetSize(playerPanelSlider, GetSliderWidth(), BlzFrameGetHeight(playerContainer))
        call BlzFrameSetMinMaxValue(playerPanelSlider, 0.0, 1.0)
        call BlzFrameSetValue(playerPanelSlider, 1.0)
        set maxValue            = 1
        //call BlzFrameSetVisible(playerPanelSlider, false)
    endmethod
    private static method initChildFrames takes nothing returns nothing
        local integer i         = 1
        local real height       = BlzFrameGetHeight(playerContainer) / I2R(GetPlayerFrameCount())
        local real guideWidth   = 0.0
        //  Create player text parameters
        set playerTextParams[1] = BlzCreateFrameByType("TEXT", "CustomRaceObserverTextGuidePlayerName", /*
                                                    */ playerTextGuide, "", 0)
        set playerTextParams[2] = BlzCreateFrameByType("TEXT", "CustomRaceObserverTextGuidePlayerSelection", /*
                                                    */ playerTextGuide, "", 0)
        set guideWidth          = GetPlayerTextGuidePlayerSelectionOffsetX()
        call BlzFrameSetSize(playerTextParams[1], guideWidth, BlzFrameGetHeight(playerTextGuide))
        set guideWidth          = BlzFrameGetWidth(playerTextGuide) - /*
                               */ GetPlayerTextGuidePlayerNameOffsetX() - /*
                               */ GetPlayerTextGuidePlayerSelectionOffsetX()
        call BlzFrameSetSize(playerTextParams[2], guideWidth, BlzFrameGetHeight(playerTextGuide))

        call BlzFrameSetPoint(playerTextParams[1], FRAMEPOINT_LEFT, playerTextGuide, FRAMEPOINT_LEFT, /*
                           */ GetPlayerTextGuidePlayerNameOffsetX(), 0.0)
        call BlzFrameSetPoint(playerTextParams[2], FRAMEPOINT_LEFT, playerTextParams[1], FRAMEPOINT_LEFT, /*
                           */ GetPlayerTextGuidePlayerSelectionOffsetX(), 0.0)
        call BlzFrameSetText(playerTextParams[1], "|cffffcc00Player:|r")
        call BlzFrameSetText(playerTextParams[2], "|cffffcc00Current Faction:|r")
        call BlzFrameSetTextAlignment(playerTextParams[1], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetTextAlignment(playerTextParams[2], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)

        set guideWidth          = BlzFrameGetWidth(playerContainer) - GetPlayerFrameWidthOffset()
        loop
            exitwhen i > GetPlayerFrameCount()
            set playerFrame[i]      = BlzCreateFrameByType("BUTTON", "CustomRaceObserverPlayerMainPanel", /*
                                                        */ playerContainer, "", i)
            set playerFrameBG[i]    = BlzCreateFrameByType("BACKDROP", "CustomRaceObserverPlayerMainPanelBG", /*
                                                        */ playerFrame[i], "CustomRaceSimpleBackdropTemplate", /*
                                                        */ i)
            set playerFrameID[GetFrameIndex(playerFrame[i])]    = i

            call BlzFrameSetSize(playerFrame[i], guideWidth, height)
            call BlzFrameSetAllPoints(playerFrameBG[i], playerFrame[i])
            if i == 1 then
                call BlzFrameSetPoint(playerFrame[i], FRAMEPOINT_TOPLEFT, playerContainer, /*
                                   */ FRAMEPOINT_TOPLEFT, GetPlayerFrameOffsetX(), /*
                                   */ GetPlayerFrameOffsetY())
            else
                call BlzFrameSetPoint(playerFrame[i], FRAMEPOINT_TOP, playerFrame[i - 1], /*
                                   */ FRAMEPOINT_BOTTOM, 0.0, 0.0)
            endif

            set playerFrameHighlight[i] = BlzCreateFrameByType("HIGHLIGHT", "CustomRaceObserverPlayerMainPanelHighlight", /*
                                                            */ playerFrame[i], "EscMenuButtonMouseOverHighlightTemplate", /*
                                                            */ i)
            call BlzFrameSetAllPoints(playerFrameHighlight[i], playerFrame[i])
            call BlzFrameSetVisible(playerFrameHighlight[i], false)

            set playerFrameName[i]      = BlzCreateFrameByType("TEXT", "CustomRaceObserverPlayerPanelPlayerName", /*
                                                            */ playerFrameBG[i], "", i)
            set playerFrameFaction[i]   = BlzCreateFrameByType("TEXT", "CustomRaceObserverPlayerPanelFaction", /*
                                                            */ playerFrameBG[i], "", i)
            call BlzFrameSetSize(playerFrameName[i], BlzFrameGetWidth(playerTextParams[1]), /*
                              */ BlzFrameGetHeight(playerTextParams[1]))
            call BlzFrameSetSize(playerFrameFaction[i], BlzFrameGetWidth(playerTextParams[2]), /*
                              */ BlzFrameGetHeight(playerTextParams[2]))
            call BlzFrameSetPoint(playerFrameName[i], FRAMEPOINT_LEFT, playerFrameBG[i], FRAMEPOINT_LEFT, /*
                           */ GetPlayerTextGuidePlayerNameOffsetX(), 0.0)
            call BlzFrameSetPoint(playerFrameFaction[i], FRAMEPOINT_LEFT, playerFrameName[i], FRAMEPOINT_LEFT, /*
                           */ GetPlayerTextGuidePlayerSelectionOffsetX(), 0.0)
            call BlzFrameSetTextAlignment(playerFrameName[i], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
            call BlzFrameSetTextAlignment(playerFrameFaction[i], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
            set i = i + 1
        endloop
    endmethod
    private static method onPlayerPanelEnter takes nothing returns nothing
        local player trigPlayer = GetTriggerPlayer()
        local integer id        = GetFrameIndex(BlzGetTriggerFrame())
        local integer i         = playerFrameID[id]
        if localPlayer == trigPlayer then
            call BlzFrameSetVisible(playerFrameHighlight[i], true)
        endif
    endmethod
    private static method onPlayerPanelLeave takes nothing returns nothing
        local player trigPlayer = GetTriggerPlayer()
        local integer id        = GetFrameIndex(BlzGetTriggerFrame())
        local integer i         = playerFrameID[id]
        if localPlayer == trigPlayer then
            call BlzFrameSetVisible(playerFrameHighlight[i], false)
        endif
    endmethod
    private static method onSliderValueChange takes nothing returns nothing
        local player trigPlayer = GetTriggerPlayer()
        local integer id        = GetPlayerId(trigPlayer)
        local integer value     = R2I(BlzGetTriggerFrameValue() + 0.01)
        if CustomRacePSelection.choicedPlayerSize <= GetPlayerFrameCount() then
            set basePlayerIndex[id] = 0
            return
        endif
        set basePlayerIndex[id] =  CustomRacePSelection.choicedPlayerSize - /*
                                */ (GetPlayerFrameCount() + value)
    endmethod
    private static method addPlayerFrameEvents takes nothing returns nothing
        local trigger enterTrig     = CreateTrigger()
        local trigger leaveTrig     = CreateTrigger()
        local integer i             = 1
        loop
            exitwhen i > GetPlayerFrameCount()
            call BlzTriggerRegisterFrameEvent(enterTrig, playerFrame[i], FRAMEEVENT_MOUSE_ENTER)
            call BlzTriggerRegisterFrameEvent(leaveTrig, playerFrame[i], FRAMEEVENT_MOUSE_LEAVE)
            set i = i + 1
        endloop
        call TriggerAddAction(enterTrig, function thistype.onPlayerPanelEnter)
        call TriggerAddAction(leaveTrig, function thistype.onPlayerPanelLeave)
    endmethod
    private static method init takes nothing returns nothing
        set localPlayer             = GetLocalPlayer()
        call thistype.initMainFrames()
        call thistype.initChildFrames()
        call thistype.addPlayerFrameEvents()
        //  Hide the frame upon at its' release state.
        call BlzFrameSetVisible(main, false)
        static if LIBRARY_FrameLoader then
            call FrameLoaderAdd(function thistype.init)
        endif
    endmethod
    implement Init
endstruct

private function CanPlayerSeeUI takes player whichPlayer returns boolean
    local boolean result    = CustomRacePSelection.hasUnchoicedPlayer(whichPlayer) or IsPlayerObserver(whichPlayer)
    static if LIBRARY_GameStatus then
        set result          = (GetGameStatus() == GAME_STATUS_REPLAY) or result
    endif
    return result
endfunction
public  function RenderFrame takes nothing returns nothing
    local string  factionText       = "No Faction Selected"
    local integer i                 = 1
    local integer id                = GetPlayerId(localPlayer)
    local integer oldBase           = CustomRaceObserverUI.maxValue
    local real preValue             = BlzFrameGetValue(CustomRaceObserverUI.playerPanelSlider)
    local CustomRacePSelection obj  = 0
    local CustomRace faction        = 0

    local player whichPlayer
    //  This is guaranteed to be a synchronous action
    if CustomRacePSelection.choicedPlayerSize > GetPlayerFrameCount() then
        set CustomRaceObserverUI.maxValue   = R2I(CustomRacePSelection.choicedPlayerSize - GetPlayerFrameCount() /*
                                              */ + 0.01)
    else
        set CustomRaceObserverUI.maxValue   = 1
    endif
    if CustomRaceObserverUI.maxValue != oldBase then
        call BlzFrameSetMinMaxValue(CustomRaceObserverUI.playerPanelSlider, 0, /*
                                    */ CustomRaceObserverUI.maxValue)
        call BlzFrameSetValue(CustomRaceObserverUI.playerPanelSlider, preValue + /*
                            */ R2I(oldBase - CustomRaceObserverUI.maxValue + 0.01))
    endif
    loop
        exitwhen (i > GetPlayerFrameCount())
        if (CustomRaceObserverUI.basePlayerIndex[id] + i > CustomRacePSelection.choicedPlayerSize) then
            //  Do not display anymore
            call BlzFrameSetVisible(CustomRaceObserverUI.playerFrame[i], false)
        else
            set whichPlayer = CustomRacePSelection.choicedPlayers[CustomRaceObserverUI.basePlayerIndex[id] + i]
            set obj         = CRPSelection[whichPlayer]
            if obj.faction != 0 then
                set faction     = CustomRace.getRaceFaction(GetPlayerRace(whichPlayer), obj.baseChoice + obj.faction)
                set factionText = faction.name
            endif
            call BlzFrameSetVisible(CustomRaceObserverUI.playerFrame[i], true)
            call BlzFrameSetText(CustomRaceObserverUI.playerFrameName[i], /*
                              */ GetPlayerName(whichPlayer))
            call BlzFrameSetText(CustomRaceObserverUI.playerFrameFaction[i], /*
                              */ factionText)
            if (not DisplayPlayerFactionChoice()) and /*
            */ (CustomRacePSelection.hasUnchoicedPlayer(localPlayer)) then
                call BlzFrameSetVisible(CustomRaceObserverUI.playerFrameFaction[i], false)
            else
                call BlzFrameSetVisible(CustomRaceObserverUI.playerFrameFaction[i], true)
            endif
        endif
        set i = i + 1
    endloop
    call BlzFrameSetVisible(CustomRaceObserverUI.main, CanPlayerSeeUI(localPlayer))
endfunction
public  function UnrenderFrame takes nothing returns nothing
    call BlzFrameSetVisible(CustomRaceObserverUI.main, false)
endfunction

endlibrary