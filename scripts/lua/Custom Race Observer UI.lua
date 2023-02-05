---@diagnostic disable: undefined-doc-name
--$ noimport
--[[
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
]]
do
    local SCOPE_PREFIX              = "CustomRaceObserverUI_"
    local locTable                  = {}

    local localPlayer               = nil
    local repVarAssigned            = false
    local isReplay                  = false

    --  =========================================================== --
    --              Observer Frame Dimension Parameters             --
    --  =========================================================== --
    --- This only applies to players. Observers will always see the
    --- faction choice.
    ---@return boolean
    function locTable.DisplayPlayerFactionChoice()
        return false
    end
    ---@return number
    function locTable.GetObserverFrameHeight()
        return 0.28
    end
    ---@return number
    function locTable.GetObserverFrameWidth()
        return 0.28
    end
    ---@return number
    function locTable.GetObserverFrameCenterX()
        return 0.40
    end
    ---@return number
    function locTable.GetObserverFrameCenterY()
        return 0.35
    end

    --  =========================================================== --
    --              Container Frame Dimension Parameters            --
    --  =========================================================== --
    ---@return number
    function locTable.GetContainerWidthOffset()
        return 0.06
    end
    ---@return number
    function locTable.GetContainerHeightOffset()
        return 0.10
    end
    ---@return userdata -- framepointtype
    function locTable.GetContainerFramePoint()
        return FRAMEPOINT_BOTTOM
    end
    ---@return number
    function locTable.GetContainerOffsetX()
        return 0.00
    end
    ---@return number
    function locTable.GetContainerOffsetY()
        return 0.01
    end

    ---@return number
    function locTable.GetPlayerTextGuideHeight()
        return 0.03
    end
    ---@return number
    function locTable.GetPlayerTextOffsetX()
        return 0.00
    end
    ---@return number
    function locTable.GetPlayerTextOffsetY()
        return -0.0075
    end

    ---@return number
    function locTable.GetPlayerTextGuidePlayerNameOffsetX()
        return 0.04
    end
    ---@return number
    function locTable.GetPlayerTextGuidePlayerSelectionOffsetX()
        return 0.08
    end

    ---@return number
    function locTable.GetSliderWidth()
        return 0.012
    end
    ---@return number
    function locTable.GetSliderOffsetX()
        return -0.006
    end
    ---@return number
    function locTable.GetSliderOffsetY()
        return 0.0
    end

    ---@return integer
    function locTable.GetPlayerFrameCount()
        return 8
    end
    ---@return number
    function locTable.GetPlayerFrameWidthOffset()
        return 0.006
    end
    ---@return number
    function locTable.GetPlayerFrameOffsetX()
        return 0.003
    end
    ---@return number
    function locTable.GetPlayerFrameOffsetY()
        return 0.0
    end

    do
        local mt                = {
            _list               = {},
        }

        ---Returns the frame index of the requested frame.
        ---@param t table
        ---@param whichFrame frame
        mt.__call               =
        function(t, whichFrame)
            if not mt._list[whichFrame] then
                mt[#mt + 1]             = whichFrame
                mt._list[whichFrame]    = #mt
            end
            return mt._list[whichFrame] or 0
        end
        locTable.GetFrameIndex  = setmetatable({}, mt)
    end

    do
        ---@class CustomRaceObserverUI
        ---@field maxValue integer
        ---@field _basePlayerIndex integer table
        ---@field _main framehandle
        ---@field _playerContainer framehandle
        ---@field _playerTextGuide framehandle
        ---@field _playerPanelSlider framehandle
        ---@field _playerTextParams framehandle
        ---@field _playerFrame framehandle table
        ---@field _playerFrameBG framehandle table
        ---@field _playerFrameHighlight framehandle table
        ---@field _playerFrameName framehandle table
        ---@field _playerFrameFaction framehandle table
        ---@private
        local cRaceObserverUI   = {
            maxValue            = 1,
            
            _basePlayerIndex        = __jarray(0),
            _main                   = nil,
            _playerContainer        = nil,
            _playerTextGuide        = nil,
            _playerPanelSlider      = nil,
            _playerTextParams       = {},

            _playerFrame            = {},
            _playerFrameBG          = {},
            _playerFrameHighlight   = {},
            _playerFrameName        = {},
            _playerFrameFaction     = {},

            __playerFrameID         = __jarray(0),
        }
        function cRaceObserverUI.initMainFrames()
            cRaceObserverUI._main   = BlzCreateFrameByType("BACKDROP",
                                      "CustomRaceObserverMainFrame",
                                      BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0),
                                      "EscMenuButtonBackdropTemplate", 0)
            BlzFrameSetSize(cRaceObserverUI._main, locTable.GetObserverFrameWidth(), locTable.GetObserverFrameHeight())
            BlzFrameSetAbsPoint(cRaceObserverUI._main, FRAMEPOINT_CENTER, locTable.GetObserverFrameCenterX(),
                                    locTable.GetObserverFrameCenterY())

            cRaceObserverUI._playerContainer     = BlzCreateFrameByType("BACKDROP", "CustomRaceObserverContainer",
                                                    main, "EscMenuControlBackdropTemplate", 0)
            BlzFrameSetSize(playerContainer, BlzFrameGetWidth(main) - locTable.GetContainerWidthOffset() / 2.0,
                                BlzFrameGetWidth(main) - locTable.GetContainerHeightOffset())
            BlzFrameSetPoint(playerContainer, locTable.GetContainerFramePoint(), main, FRAMEPOINT_BOTTOM,
                                locTable.GetContainerOffsetX(), locTable.GetContainerOffsetY())
    
            cRaceObserverUI._playerTextGuide     = BlzCreateFrameByType("BACKDROP", "CustomRaceObserverTextGuide",
                                                    main, "EscMenuControlBackdropTemplate", 0)
            BlzFrameSetSize(playerTextGuide, BlzFrameGetWidth(playerContainer),
                                locTable.GetPlayerTextGuideHeight())
            BlzFrameSetPoint(playerTextGuide, FRAMEPOINT_BOTTOM, playerContainer,
                                FRAMEPOINT_TOP, locTable.GetPlayerTextOffsetX(), locTable.GetPlayerTextOffsetY())
    
            cRaceObserverUI._playerPanelSlider   = BlzCreateFrameByType("SLIDER", "CustomRaceObserverPlayerPanelSlider",
                                                        playerContainer, "EscMenuSliderTemplate", 0)
            BlzFrameSetPoint(playerPanelSlider, FRAMEPOINT_LEFT, playerContainer, FRAMEPOINT_RIGHT,
                                locTable.GetSliderOffsetX(), locTable.GetSliderOffsetY())
            BlzFrameSetSize(playerPanelSlider, locTable.GetSliderWidth(), BlzFrameGetHeight(playerContainer))
            BlzFrameSetMinMaxValue(playerPanelSlider, 0.0, 1.0)
            BlzFrameSetValue(playerPanelSlider, 1.0)
            cRaceObserverUI.maxValue            = 1
            //call BlzFrameSetVisible(playerPanelSlider, false)
        end
    end

    private static method initMainFrames takes nothing returns nothing
        set main                = BlzCreateFrameByType("BACKDROP", "CustomRaceObserverMainFrame", /*
                                        BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), /*
                                        */ "EscMenuButtonBackdropTemplate", 0)
        call BlzFrameSetSize(main, locTable.GetObserverFrameWidth(), locTable.GetObserverFrameHeight())
        call BlzFrameSetAbsPoint(main, FRAMEPOINT_CENTER, locTable.GetObserverFrameCenterX(), /*
                              */ locTable.GetObserverFrameCenterY())
        
        set playerContainer     = BlzCreateFrameByType("BACKDROP", "CustomRaceObserverContainer", /*
                                                */ main, "EscMenuControlBackdropTemplate", 0)
        call BlzFrameSetSize(playerContainer, BlzFrameGetWidth(main) - locTable.GetContainerWidthOffset() / 2.0, /*
                          */ BlzFrameGetWidth(main) - locTable.GetContainerHeightOffset())
        call BlzFrameSetPoint(playerContainer, locTable.GetContainerFramePoint(), main, FRAMEPOINT_BOTTOM, /*
                           */ locTable.GetContainerOffsetX(), locTable.GetContainerOffsetY())

        set playerTextGuide     = BlzCreateFrameByType("BACKDROP", "CustomRaceObserverTextGuide", /*
                                                */ main, "EscMenuControlBackdropTemplate", 0)
        call BlzFrameSetSize(playerTextGuide, BlzFrameGetWidth(playerContainer), /*
                          */ locTable.GetPlayerTextGuideHeight())
        call BlzFrameSetPoint(playerTextGuide, FRAMEPOINT_BOTTOM, playerContainer, /*
                           */ FRAMEPOINT_TOP, locTable.GetPlayerTextOffsetX(), locTable.GetPlayerTextOffsetY())

        set playerPanelSlider   = BlzCreateFrameByType("SLIDER", "CustomRaceObserverPlayerPanelSlider", /*
                                                    */ playerContainer, "EscMenuSliderTemplate", 0)
        call BlzFrameSetPoint(playerPanelSlider, FRAMEPOINT_LEFT, playerContainer, FRAMEPOINT_RIGHT, /*
                           */ locTable.GetSliderOffsetX(), locTable.GetSliderOffsetY())
        call BlzFrameSetSize(playerPanelSlider, locTable.GetSliderWidth(), BlzFrameGetHeight(playerContainer))
        call BlzFrameSetMinMaxValue(playerPanelSlider, 0.0, 1.0)
        call BlzFrameSetValue(playerPanelSlider, 1.0)
        set maxValue            = 1
        //call BlzFrameSetVisible(playerPanelSlider, false)
    endmethod
    private static method initChildFrames takes nothing returns nothing
        local integer i         = 1
        local real height       = BlzFrameGetHeight(playerContainer) / I2R(locTable.GetPlayerFrameCount())
        local real guideWidth   = 0.0
        //  Create player text parameters
        set playerTextParams[1] = BlzCreateFrameByType("TEXT", "CustomRaceObserverTextGuidePlayerName", /*
                                                    */ playerTextGuide, "", 0)
        set playerTextParams[2] = BlzCreateFrameByType("TEXT", "CustomRaceObserverTextGuidePlayerSelection", /*
                                                    */ playerTextGuide, "", 0)
        set guideWidth          = locTable.GetPlayerTextGuidePlayerSelectionOffsetX()
        call BlzFrameSetSize(playerTextParams[1], guideWidth, BlzFrameGetHeight(playerTextGuide))
        set guideWidth          = BlzFrameGetWidth(playerTextGuide) - /*
                               */ locTable.GetPlayerTextGuidePlayerNameOffsetX() - /*
                               */ locTable.GetPlayerTextGuidePlayerSelectionOffsetX()
        call BlzFrameSetSize(playerTextParams[2], guideWidth, BlzFrameGetHeight(playerTextGuide))

        call BlzFrameSetPoint(playerTextParams[1], FRAMEPOINT_LEFT, playerTextGuide, FRAMEPOINT_LEFT, /*
                           */ locTable.GetPlayerTextGuidePlayerNameOffsetX(), 0.0)
        call BlzFrameSetPoint(playerTextParams[2], FRAMEPOINT_LEFT, playerTextParams[1], FRAMEPOINT_LEFT, /*
                           */ locTable.GetPlayerTextGuidePlayerSelectionOffsetX(), 0.0)
        call BlzFrameSetText(playerTextParams[1], "|cffffcc00Player:|r")
        call BlzFrameSetText(playerTextParams[2], "|cffffcc00Current Faction:|r")
        call BlzFrameSetTextAlignment(playerTextParams[1], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetTextAlignment(playerTextParams[2], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)

        set guideWidth          = BlzFrameGetWidth(playerContainer) - locTable.GetPlayerFrameWidthOffset()
        loop
            exitwhen i > locTable.GetPlayerFrameCount()
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
                                   */ FRAMEPOINT_TOPLEFT, locTable.GetPlayerFrameOffsetX(), /*
                                   */ locTable.GetPlayerFrameOffsetY())
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
                           */ locTable.GetPlayerTextGuidePlayerNameOffsetX(), 0.0)
            call BlzFrameSetPoint(playerFrameFaction[i], FRAMEPOINT_LEFT, playerFrameName[i], FRAMEPOINT_LEFT, /*
                           */ locTable.GetPlayerTextGuidePlayerSelectionOffsetX(), 0.0)
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
        if CustomRacePSelection.choicedPlayerSize <= locTable.GetPlayerFrameCount() then
            set basePlayerIndex[id] = 0
            return
        endif
        set basePlayerIndex[id] =  CustomRacePSelection.choicedPlayerSize - /*
                                */ (locTable.GetPlayerFrameCount() + value)
    endmethod
    private static method addPlayerFrameEvents takes nothing returns nothing
        local trigger enterTrig     = CreateTrigger()
        local trigger leaveTrig     = CreateTrigger()
        local integer i             = 1
        loop
            exitwhen i > locTable.GetPlayerFrameCount()
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
    if CustomRacePSelection.choicedPlayerSize > locTable.GetPlayerFrameCount() then
        set CustomRaceObserverUI.maxValue   = R2I(CustomRacePSelection.choicedPlayerSize - locTable.GetPlayerFrameCount() /*
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
        exitwhen (i > locTable.GetPlayerFrameCount())
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
            if (not locTable.DisplayPlayerFactionChoice()) and /*
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

end