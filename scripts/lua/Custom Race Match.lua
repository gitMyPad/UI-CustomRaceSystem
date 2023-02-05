--[[
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
]]
do
    local locTable                                          = {fourCC = FourCC}
    local SCOPE_PREFIX                                      = "CustomRaceMatch_"

    --  =====================================================   --
    --              CONFIGURABLES Section                       --
    --  =====================================================   --
    local FOGGED_START                                      = false
    local USE_EXTRA_TICK                                    = true
    _G[SCOPE_PREFIX .. "APPLY_TIMER_IN_SINGLE_PLAYER"]      = false

    local APPLY_TIMER_IN_SINGLE_PLAYER                      = _G[SCOPE_PREFIX .. "APPLY_TIMER_IN_SINGLE_PLAYER"]
    local GAME_START_TICKS                                  = 3
    local EXTRA_TICK_FOR_START                              = 1
    local TICK_INTERVAL                                     = 1.0
    local DISPLAY_LIFETIME                                  = 0.8
    local DISPLAY_INTERVAL                                  = 1.0 / 100.0
    --  =====================================================   --
    --              End CONFIGURABLES Section                   --
    --  =====================================================   --

    --  =============================================================================   --
    function locTable.ClearMusicPlaylist()
        --  Observers can't play any faction playlist,
        --  so return at this point. Comment later
        --  if this causes desyncs.
        if IsPlayerObserver(GetLocalPlayer()) then
            return
        end
        ClearMapMusic()
        StopMusic(false)
    end
    --  =============================================================================   --

    --  =============================================================================   --
    --  In previous versions, visibility was actually affected.
    --  In modern versions, visibility is kept intact and only
    --  the time of day is affected.
    --  =============================================================================   --
    function locTable.StartingVisibility()
        SetFloatGameState(GAME_STATE_TIME_OF_DAY, bj_MELEE_STARTING_TOD)
        SuspendTimeOfDay(true)
        if FOGGED_START then
            FogMaskEnable(true)
            FogEnable(true)
        end
    end
    --  =============================================================================   --

    --  =============================================================================   --
    function locTable.StartingHeroLimit()
        local maxHeroIndex  = CustomRace.getGlobalHeroMaxIndex()    -- integer
        local whichPlayer                                           -- player
        for index = 0, bj_MAX_PLAYERS, 1 do
            whichPlayer = Player(index)
            SetPlayerTechMaxAllowed(whichPlayer, locTable.fourCC('HERO'), bj_MELEE_HERO_LIMIT)
            for i       = 1, maxHeroIndex, 1 do
                SetPlayerTechMaxAllowed(whichPlayer, CustomRace.getGlobalHero(i),  bj_MELEE_HERO_TYPE_LIMIT)
            end
        end
    end
    --  =============================================================================   --

    --  =============================================================================   --
    ---@param hero userdata - unit
    function locTable.GrantItem(hero)
        if IsUnitType(hero, UNIT_TYPE_HERO) then
            MeleeGrantItemsToHero(hero)
        end
    end
    function locTable.OnNeutralHeroHired()
        GrantItem(GetSoldUnit())
    end
    function locTable.OnTrainedHeroFinish()
        GrantItem(GetTrainedUnit())
    end
    function locTable.GrantHeroItems()
        local trig              = CreateTrigger()       -- trigger
        local whichPlayer       = nil                   -- player
        TriggerAddAction(trig, locTable.OnTrainedHeroFinish)

        for index   = 0, bj_MAX_PLAYER_SLOTS, 1 do
            -- Initialize the twinked hero counts.
            bj_meleeTwinkedHeroes[index]    = 0
            whichPlayer                     = Player(index)
            
            -- Register for an event whenever a hero is trained, so that we can give
            -- him/her their starting items. Exclude
            if ((index < bj_MAX_PLAYERS) and 
                (IsPlayerActive(whichPlayer))) then
                TriggerRegisterPlayerUnitEvent(trig, whichPlayer, EVENT_PLAYER_UNIT_TRAIN_FINISH, nil)
            end
        end

        -- Register for an event whenever a neutral hero is hired, so that we
        -- can give him/her their starting items.
        trig    = CreateTrigger()
        TriggerRegisterPlayerUnitEvent(trig, Player(PLAYER_NEUTRAL_PASSIVE), EVENT_PLAYER_UNIT_SELL, nil)
        TriggerAddAction(trig, locTable.OnNeutralHeroHired)
        trig    = nil

        -- Flag that we are giving starting items to heroes, so that the melee
        -- starting units code can create them as necessary.
        bj_meleeGrantHeroItems = true
    end
    --  =============================================================================   --

    --  =============================================================================   --
    function locTable.StartingResources()
        local whichPlayer                                       -- player
        local v                                                 -- version handle
        local startingGold      = bj_MELEE_STARTING_GOLD_V1     -- integer
        local startingLumber    = bj_MELEE_STARTING_LUMBER_V1   -- integer

        v = VersionGet()
        if (v == VERSION_REIGN_OF_CHAOS) then
            startingGold = bj_MELEE_STARTING_GOLD_V0
            startingLumber = bj_MELEE_STARTING_LUMBER_V0
        end

        -- Set each player's starting resources.
        for index = 0, bj_MAX_PLAYERS - 1, 1 do
            whichPlayer = Player(index)
            if CustomRaceMatchConditions_IsPlayerActive(whichPlayer) then
                SetPlayerState(whichPlayer, PLAYER_STATE_RESOURCE_GOLD, startingGold)
                SetPlayerState(whichPlayer, PLAYER_STATE_RESOURCE_LUMBER, startingLumber)
            end
        end
    end
    --  =============================================================================   --

    --  =============================================================================   --
    ---Removes all neutral hostile units (including structures) and neutral passive
    ---units (excluding structures).
    ---@param x number
    ---@param y number
    ---@param radius number
    function locTable.RemoveNearbyUnits(x, y, radius)
        local owner         = 0             -- integer
        local size          = 0             -- integer
        local nearbyUnits   = CreateGroup() -- group
        local enumUnit                      -- unit

        GroupEnumUnitsInRange(nearbyUnits, x, y, radius, nil)
        size        = BlzGroupGetSize(nearbyUnits)
        for i = 0, size - 1, 1 do
            enumUnit    = BlzGroupUnitAt(nearbyUnits, i)
            owner       = GetPlayerId(GetOwningPlayer(enumUnit))
            if (owner == PLAYER_NEUTRAL_AGGRESSIVE) or 
               ((owner == PLAYER_NEUTRAL_PASSIVE) and 
                (not IsUnitType(enumUnit, UNIT_TYPE_STRUCTURE))) then
                -- Remove any Neutral Hostile units or
                -- Neutral Passive units (not structures) from the area.
                RemoveUnit(enumUnit)
            end
        end
        DestroyGroup(nearbyUnits)
        enumUnit    = nil
    end
    function locTable.ClearExcessUnits()
        local locX          -- number
        local locY          -- number
        local indexPlayer   -- player

        for index = 0, bj_MAX_PLAYERS - 1, 1 do
            indexPlayer = Player(index)
            -- If the player slot is being used, clear any nearby creeps.
            if CustomRaceMatchConditions_IsPlayerActive(indexPlayer) then
                locX = GetStartLocationX(GetPlayerStartLocation(indexPlayer))
                locY = GetStartLocationY(GetPlayerStartLocation(indexPlayer))
                locTable.RemoveNearbyUnits(locX, locY, bj_MELEE_CLEAR_UNITS_RADIUS)
            end
        end
    end
    --  =============================================================================   --

    --  =============================================================================   --
    function locTable.DefineVictoryDefeat()
        --  Unravelling this function will open a can of worms
        --  the likes which would not likely be appreciated.
        --  Leave it as it is, and make changes in a separate
        --  library specifically for this function.
        CustomRaceMatchConditions_DefineVictoryDefeat()
    end
    --  =============================================================================   --

    --  =============================================================================   --
    function locTable.OnStartCheckAlliance()
        local whichTimer  = GetExpiredTimer()   -- timer
        PauseTimer(whichTimer)
        DestroyTimer(whichTimer)
        CustomRaceMatchConditions_OnAllianceChange()
    end
    function locTable.TestVictoryDefeat()
        -- Test for victory / defeat at startup, in case the user has already won / lost.
        -- Allow for a short time to pass first, so that the map can finish loading.
        TimerStart(CreateTimer(), 2.0, false, locTable.OnStartCheckAlliance)
    end
    --  =============================================================================   --

    --  =============================================================================   --
    do
        local tempStart                 = 0
        local tempStartLoc              = nil   -- location
        local tempStartPlayer           = nil

        function locTable.OnStartGetPlayer()
            return tempStartPlayer
        end
        function locTable.OnStartGetLoc()
            return tempStartLoc
        end
        function locTable.StartingUnits()
            local obj                       -- CustomRacePSelection
            local faction                   -- CustomRace
            local indexPlayer               -- player
            local pRace                     -- race
        
            Preloader( "scripts\\SharedMelee.pld" )
            for index = 1, CustomRacePSelection.unchoicedPlayerSize, 1 do
                indexPlayer     = CustomRacePSelection._unchoiced[index]
                tempStartPlayer = indexPlayer
                tempStart       = GetPlayerStartLocation(indexPlayer)
                tempStartLoc    = GetStartLocationLoc(tempStart)
                pRace           = GetPlayerRace(indexPlayer)
                obj             = CRPSelection[indexPlayer]
                faction         = CustomRace.getRaceFaction(pRace, obj.faction)
                
                faction:execSetup()
                if GetPlayerController(indexPlayer) == MAP_CONTROL_COMPUTER then
                    faction:execSetupAI()
                end
                RemoveLocation(tempStartLoc)
            end
            --  Do NOT make these usable afterwards!
            tempStartPlayer = nil
            tempStart       = 0
            tempStartLoc    = nil
        end
    end
    --  =============================================================================   --

    --  =============================================================================   --
    do
        ---@class FrameInterpolation
        local FrameInterpolation        = {_G = _G}
        do
            FrameInterpolation.__index      = FrameInterpolation
            FrameInterpolation.__newindex   =
            function(t, k, v)
                if FrameInterpolation[k] then
                    return t
                end
                return rawset(t, k, v)
            end

        end
        local function chunk_loader()
            local _ENV              = FrameInterpolation
            
    --  =============================================================================   --
        FRAME_SCALE             = 10.0
        FRAME_ENDSCALE          = 10.0
        START_X                 = 0.40
        END_X                   = 0.40
        START_Y                 = 0.45
        END_Y                   = 0.25
        POINT                   = _G.FRAMEPOINT_CENTER

        objectList              = {}
        objectCurIndex          = 0
        interpolator            = _G.CreateTimer()

        ---A function that informs the system how to interpolate the alpha color
        ---of the popup text.
        ---@param x number
        ---@return number
        function alphaResponse(x)
            x   = x - 0.5
            return -16.0*(x*x*x*x) + 1.0
        end

        ---A function that informs the system how to interpolate the sliding behavior
        ---of the popup text.
        ---@param x number
        ---@return number
        function slideResponse(x)
            x   = x - 0.5
            return -4.0*(x*x*x) + 0.5
        end
        ---A function that informs the system how to interpolate the scaling behavior
        ---of the popup text.
        ---@param x number
        ---@return number
        function scaleResponse(x)
            return -(x*x*x*x*x*x) + 1.0
        end

        ---Destroys the FrameInterpolation instance, along with the popup text.
        ---@param self FrameInterpolation -- the caller
        function destroy(self)
            BlzFrameSetVisible(self.frame, false)
            BlzDestroyFrame(self.frame)
            self.message    = nil
            self.frame      = nil
            self.ticks      = 0
            self.maxTicks   = 0
            setmetatable(self, nil)
        end

        ---Periodically runs until all FrameInterpolation instances are done.
        function onUpdate()
            local this                  -- FrameInterpolation
            local ratio         = 0.0   -- number
            local resp          = 0.0   -- number
            local cx            = 0.0   -- number
            local cy            = 0.0   -- number
            local scale         = 0.0   -- number
            for i = 1, objectCurIndex, 1 do
                this        = objectList[i]
                this.ticks  = this.ticks + 1
                ratio       = I2R(this.ticks) / I2R(this.maxTicks)
                _G.BlzFrameSetAlpha(this.frame, R2I(255.0*thistype.alphaResponse(ratio)))

                resp        = slideResponse(ratio)
                cx          = START_X*resp + END_X*(1-resp)
                cy          = START_Y*resp + END_Y*(1-resp)

                resp        = scaleResponse(ratio)
                scale       = FRAME_SCALE*resp + FRAME_ENDSCALE*(1-resp)
                _G.BlzFrameSetAbsPoint(this.frame, POINT, cx, cy)
                _G.BlzFrameSetScale(this.frame, scale)

                if this.ticks >= this.maxTicks then
                    objectList[i]               = objectList[objectCurIndex]
                    objectList[objectCurIndex]  = nil
                    objectCurIndex              = objectCurIndex - 1
                    i                           = i - 1
                    this:destroy()
                end
            end
            if objectCurIndex < 1 then
                _G.PauseTimer(interpolator)
            end
        end

        ---Inserts a FrameInterpolation instance to the objectList {},
        ---starting the interpolator timer if it is the first instance of the list.
        ---@param this FrameInterpolation
        function insertToObjectList(this)
            objectCurIndex              = objectCurIndex + 1
            objectList[objectCurIndex]  = this
            if (objectCurIndex == 1) then
                _G.TimerStart(interpolator, DISPLAY_INTERVAL, true, onUpdate)
            end
        end

        ---Creates a new FrameInterpolation instance based on the fed data and
        ---immediately acts upon it.
        ---@param msg string
        ---@param lifetime number
        function request(msg, lifetime)
            ---@type FrameInterpolation
            local this          = setmetatable({
                message         = msg,
                maxTicks        = _G.R2I(lifetime / DISPLAY_INTERVAL + 0.01),
                ticks           = 0,
                frame           = _G.BlzCreateFrameByType("TEXT", "CustomRaceMatchDisplayText",
                                                          BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI,
                                                          0), "", integer(this)),
            }, FrameInterpolation)
            _G.BlzFrameSetText(this.frame, message)
            _G.BlzFrameSetScale(this.frame, FRAME_SCALE)
            _G.BlzFrameSetAlpha(this.frame, 0)
            _G.BlzFrameSetAbsPoint(this.frame, POINT, START_X, START_Y)
            insertToObjectList(this)
        end
    --  =============================================================================   --
        end
        chunk_loader()

        locTable.DisplayToWorld = FrameInterpolation.request
    end
    --  =============================================================================   --

    --  =============================================================================   --
    do
        local beginTick         = 0     -- integer
        local extraTick         = 0     -- integer
        local tickGroup                 -- group
        local tempSound                 -- sound

        function locTable.GenerateTickSound()
            tempSound   = CreateSound( "Sound\\Interface\\BattleNetTick.wav", false, false, false, 10, 10, "" )
            SetSoundParamsFromLabel( tempSound, "ChatroomTimerTick" )
            SetSoundDuration( tempSound, 476 )
            return tempSound
        end
        function locTable.GenerateHornSound()
            tempSound   = CreateSound( "Sound\\Ambient\\DoodadEffects\\TheHornOfCenarius.wav", false, false, false, 10, 10, "DefaultEAXON" )
            SetSoundParamsFromLabel( tempSound, "HornOfCenariusSound" )
            SetSoundDuration( tempSound, 12120 )
            return tempSound
        end
        function locTable.PlaySoundForPlayer(whichSound, whichPlayer)
            if GetLocalPlayer() ~= whichPlayer then
                SetSoundVolume(whichSound, 0)
            end
            StartSound(whichSound)
            KillSoundWhenDone(whichSound)
        end
    --  =============================================================================   --
        function locTable.SetupPlaylist()
            local whichPlayer   = GetLocalPlayer()              -- player
            local obj           = CRPSelection[whichPlayer]     -- CustomRacePSelection
            local faction       = CustomRace.getRaceFaction(GetPlayerRace(whichPlayer), obj.faction)    -- CustomRace instances in Lua are table objects.
            if faction == nil then
                return
            end
            SetMapMusic(faction.playlist, true, 0)
            PlayMusic(faction.playlist)
        end
        function locTable.ResetVisuals()
            EnableDragSelect(true, true)
            EnablePreSelect(true, true)
            EnableSelect(true, true)
            EnableUserControl(true)
            EnableUserUI(true)
            SuspendTimeOfDay(false)
        end
        function locTable.MatchTickDown()
            local size              = 0 -- integer
            local expTimer              -- timer
            beginTick               = beginTick - 1
            if beginTick > 0 then
                StartSound(locTable.GenerateTickSound())
                KillSoundWhenDone(tempSound)
                locTable.DisplayToWorld(I2S(beginTick), DISPLAY_LIFETIME)
                return
            end

            extraTick               = extraTick - 1
            if extraTick > 0 then
                return
            end
            StartSound(locTable.GenerateHornSound())
            KillSoundWhenDone(tempSound)
            locTable.DisplayToWorld("|cffff4040Start!|r", 1.20)

            expTimer                = GetExpiredTimer()
            PauseTimer(expTimer)
            DestroyTimer(expTimer)

            locTable.TestVictoryDefeat()
            locTable.ResetVisuals()
            locTable.SetupPlaylist()

            size                    = BlzGroupGetSize(tickGroup)
            for i = 0, size - 1, 1 do
                PauseUnit(BlzGroupUnitAt(tickGroup, i), false)
            end
            DestroyGroup(tickGroup)
        end
        function locTable.SetupVisuals()
            local real zdist    = GetCameraField(CAMERA_FIELD_TARGET_DISTANCE)
            local real ndist    = zdist + 1250.0
            if IsPlayerInForce(GetLocalPlayer(), CustomRaceForce.activePlayers) then
                SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, ndist, 0.00)
                SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, zdist, 0.00)
            end
            EnableDragSelect(false, false)
            EnablePreSelect(false, false)
            EnableSelect(false, false)
            EnableUserControl(false)
            EnableUserUI(false)
        end
        function locTable.BeginMatch()
            local world         = GetWorldBounds()  -- rect
            local integer i     = 0
            local size          = 0                 -- integer
            tickGroup           = CreateGroup()
            beginTick           = GAME_START_TICKS + 1
            if USE_EXTRA_TICK then
                extraTick       = EXTRA_TICK_FOR_START
            end
            TimerStart(CreateTimer(), TICK_INTERVAL, true, locTable.MatchTickDown)
            locTable.SetupVisuals()
            GroupEnumUnitsInRect(tickGroup, world, nil)

            size                = BlzGroupGetSize(tickGroup)
            for i = 0, size - 1, 1 do
                PauseUnit(BlzGroupUnitAt(tickGroup, i), true)
            end
            --  Cleaned up, thanks to Jass Script Helper.
            RemoveRect(world)
        end
    end
    --  =============================================================================   --

    --  =============================================================================   --
    function locTable.MeleeInitialization()
        locTable.ClearMusicPlaylist()
        locTable.StartingVisibility()
        locTable.StartingHeroLimit()
        locTable.GrantHeroItems()
        locTable.StartingResources()
        locTable.ClearExcessUnits()
    end
    _G[SCOPE_PREFIX .. "MeleeInitialization"]           = locTable.MeleeInitialization

    function locTable.MeleeInitializationFinish()
        locTable.DefineVictoryDefeat()
        locTable.StartingUnits()
        locTable.BeginMatch()
    end
    _G[SCOPE_PREFIX .. "MeleeInitializationFinish"]     = locTable.MeleeInitializationFinish

end