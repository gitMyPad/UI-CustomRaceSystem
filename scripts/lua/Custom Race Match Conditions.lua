---@diagnostic disable: undefined-doc-name, cast-local-type
--[[
library CustomRaceMatchConditions requires

    ----------------------
    */  CustomRaceCore, /*
    ----------------------

    ------------------------------
    */  CustomRacePSelection,   /*
    ------------------------------

    ----------------------
    */  Init,           /*
    ----------------------

     ---------------------------------------------------
    |
    |       CustomRaceMatchConditions
    |
    |---------------------------------------------------
    |
    |   The part of the Custom Race system that I abhor
    |   tinkering with. Making this behave as close to
    |   the original melee conditions as possible was
    |   quite tedious on my part, but I eventually succeeded.
    |
    |   OPTIMIZE at your own risk!
    |
     ---------------------------------------------------
]]
do
    local crForce       = {
        activePlayers   = CreateForce(),
        firstPlayer     = Player(0),
        __metatable     = true,
    }
    local locTable      = {}
    CustomRaceForce     = setmetatable({}, crForce)

    --  ======================================  --
    --              Global Arrays               --
    --  ======================================  --
    ---@type userdata -> force
    local allyTeam      = {}
    ---@type userdata -> force
    local enemyTeam     = {}
    ---@type integer
    local allyCount     = __jarray(0)
    ---@type integer
    local enemyCount    = __jarray(0)
    ---@type boolean
    local userOnStart   = __jarray(false)
    ---@type boolean
    local activeOnStart = __jarray(false)
    ---@type boolean
    local controlShared = __jarray(false)

    --  ======================================  --
    --              Global variables            --
    --  ======================================  --
    ---@type number
    local CRIPPLE_TIME  = bj_MELEE_CRIPPLE_TIMEOUT

    --  ======================================  --
    --         class CustomRaceForce            --
    --  ======================================  --
    do
        crForce.__index     =
        function(t, k)
            if (type(crForce[k]) ~= 'table') then
                return crForce[k]
            end
            if  (type(crForce[k].get) ~= 'function') then
                return crForce[k].get
            end
            return crForce[k].get(t)
        end
        crForce.__newindex  =
        function(t, k, v)
            if not crForce[k] then
                return rawset(t, k, v)
            end
            if (type(crForce[k]) ~= 'table') or (type(crForce[k].set) ~= 'function') then
                return t
            end
            return crForce[k].set(t, v)
        end

        --- This is an enumerating function, not meant for direct access anywhere
        function crForce._getFirst()
            if crForce.firstPlayer ~= nil then
                return
            end
            crForce.firstPlayer = GetEnumPlayer()
        end

        ---This is an operator meant for safely getting the first player (via GetEnumPlayer)
        ---in the group of active players.
        crForce.first       = {
            get             =
            function(t)
                crForce.firstPlayer = nil
                ForForce(crForce.activePlayers, crForce._getFirst)
                return crForce.firstPlayer
            end,
        }
    end

    --  =============================================================================   --
    --                      Active Player Status API                                    --
    --  =============================================================================   --
    locTable.playerState    = {}
    local SCOPE_PREFIX      = "CustomRaceMatchConditions_"

    ---Checks whether the specified player is currently active in the game. Does not
    ---consider observers as active players.
    ---@param whichPlayer userdata -> player
    ---@return boolean
    function locTable.playerState.IsPlayerActive(whichPlayer)
        return (GetPlayerSlotState(whichPlayer) == PLAYER_SLOT_STATE_PLAYING) and
               (not IsPlayerObserver(whichPlayer))
    end
    _G[SCOPE_PREFIX .. "IsPlayerActive"]    = locTable.playerState.IsPlayerActive

    ---Used to check when the specified player was active and is no longer active,
    ---and vice versa.
    ---@param whichPlayer userdata -> player
    ---@return boolean
    function locTable.playerState.WasPlayerActive(whichPlayer)
        return activeOnStart[GetPlayerId(whichPlayer)]
    end

    ---Checks if the player was an active human player. 
    ---@param whichPlayer userdata -> player
    ---@return boolean
    function locTable.playerState.WasPlayerUser(whichPlayer)
        return locTable.playerState.WasPlayerActive(whichPlayer) and
               userOnStart[GetPlayerId(whichPlayer)]
    end

    ---@param id integer -> player ID
    ---@param opID integer -> opponent's player ID
    ---@return boolean
    function locTable.playerState.IsPlayerOpponent(id, opID)
        local thePlayer      = Player(id)
        local theOpponent    = Player(opID)
        -- The player himself is not an opponent.
        -- Players that aren't playing aren't opponents.
        -- Neither are players that are already defeated.
        if (id == opID) or
           (GetPlayerSlotState(theOpponent) ~= PLAYER_SLOT_STATE_PLAYING) or
           (bj_meleeDefeated[opID]) then
            return false
        end
        -- Allied players with allied victory set are not opponents.
        if (GetPlayerAlliance(thePlayer, theOpponent, ALLIANCE_PASSIVE)) and
           (GetPlayerAlliance(theOpponent, thePlayer, ALLIANCE_PASSIVE)) and
           (GetPlayerState(thePlayer, PLAYER_STATE_ALLIED_VICTORY) == 1) and
           (GetPlayerState(theOpponent, PLAYER_STATE_ALLIED_VICTORY) == 1) then
            return false
        end
        return true
    end
    --  =============================================================================   --

    --  =============================================================================   --
    --                      Player Surrender API                                        --
    --  =============================================================================   --
    locTable.surrender  = {}
    --- This function causes all units owned by 
    function locTable.surrender.UnitSurrender()
        SetUnitOwner(GetEnumUnit(), Player(bj_PLAYER_NEUTRAL_VICTIM), false)
    end

    ---Stores the game result for the specified player at the moment of defeat
    ---and transfers ownership of their units to the neutral player (victim) slot.
    ---@param whichPlayer player
    function locTable.surrender.PlayerSurrender(whichPlayer)
        ---@type userdata -> group
        local playerUnits       = CreateGroup()
        CachePlayerHeroData(whichPlayer)
        GroupEnumUnitsOfPlayer(playerUnits, whichPlayer, nil)
        ForGroup(playerUnits, locTable.surrender.UnitSurrender)
        DestroyGroup(playerUnits)
        playerUnits             = nil
    end

    function locTable.surrender.TeamSurrenderEnum()
        locTable.surrender.PlayerSurrender(GetEnumPlayer())
    end

    ---All allies of the player are forced to surrender.
    ---@param whichPlayer player
    function locTable.surrender.TeamSurrender(whichPlayer)
        local playerIndex       = GetPlayerId(whichPlayer) + 1
        ForForce(allyTeam[playerIndex], locTable.surrender.TeamSurrenderEnum)
    end

    --  =============================================================================   --
    --                          Shared Unit Control functions                           --
    --  =============================================================================   --
    locTable.teamControl        = {}
    do
        local shareCheckPlayer  = nil

        function locTable.teamControl.TeamGainControl()
            local enumPlayer    = GetEnumPlayer()
            if (PlayersAreCoAllied(shareCheckPlayer, enumPlayer)) and
               (shareCheckPlayer ~= enumPlayer) then
                SetPlayerAlliance(shareCheckPlayer, enumPlayer, ALLIANCE_SHARED_VISION, true)
                SetPlayerAlliance(shareCheckPlayer, enumPlayer, ALLIANCE_SHARED_CONTROL, true)
                SetPlayerAlliance(enumPlayer, shareCheckPlayer, ALLIANCE_SHARED_CONTROL, true)
                SetPlayerAlliance(shareCheckPlayer, enumPlayer, ALLIANCE_SHARED_ADVANCED_CONTROL, true)
            end
        end

        ---Grants the allies of the affected player shared control over its units.
        ---@param whichPlayer player
        function locTable.teamControl.TeamShare(whichPlayer)
            local playerIndex   = GetPlayerId(whichPlayer) + 1
            local curFaction    = CustomRace.getRaceFaction(GetPlayerRace(whichPlayer), 
                                                            CRPSelection[whichPlayer].faction)
            controlShared[playerIndex - 1]  = true
            shareCheckPlayer                = whichPlayer
            ForForce(allyTeam[playerIndex], locTable.teamControl.TeamGainControl)
            SetPlayerController(whichPlayer, MAP_CONTROL_COMPUTER)
            curFaction.execSetupAI()
        end
    end

    --  =============================================================================   --
    --                          Structure Count functions                               --
    --  =============================================================================   --
    locTable.structureCount         = {}
    do
        local allyStructures        = 0
        local allyKeyStructures     = 0
        local allyCountEnum         = 0
        local checkPlayer           = nil
        local allyGrp               = nil

        function locTable.structureCount.AllyCountEnum()
            local enumPlayer        = GetEnumPlayer()
            local playerIndex       = GetPlayerId(enumPlayer)
            if (not bj_meleeDefeated[playerIndex]) and 
               (checkPlayer ~= enumPlayer) then
                allyCountEnum = allyCountEnum + 1
            end
        end

        ---Returns the number of active allied players for the specified player.
        ---@param whichPlayer player
        ---@return integer
        function locTable.structureCount.GetAllyCount(whichPlayer)
            allyCountEnum   = 0
            checkPlayer     = whichPlayer
            ForForce(allyTeam[GetPlayerId(whichPlayer) + 1], locTable.structureCount.AllyCountEnum)
            return allyCountEnum
        end

        ---A filter function to determine eligible structures (e.g. Town Halls).
        ---@return boolean
        function locTable.structureCount.GetAllyKeyStructureCountEnum()
            return UnitAlive(GetFilterUnit()) and 
                   CustomRace.isKeyStructure(GetUnitTypeId(GetFilterUnit()))
        end

        ---A callback function that updates the number of regular structures and
        ---key structures of allied players that are still active.
        function locTable.structureCount.OnEnumAllyStructureCount()
            local enumPlayer            = GetEnumPlayer()
            GroupEnumUnitsOfPlayer(allyGrp, enumPlayer,
                                   Filter(locTable.structureCount.GetAllyKeyStructureCountEnum))
            allyStructures              = allyStructures + GetPlayerStructureCount(enumPlayer, true)
            allyKeyStructures           = allyKeyStructures + BlzGroupGetSize(allyGrp)
        end

        ---A function which checks the number of structures (key or not) for each
        ---active player allied to the queried player.
        ---@param whichPlayer player
        function locTable.structureCount.EnumAllyStructureCount(whichPlayer)
            local playerIndex           = GetPlayerId(whichPlayer) + 1
            allyStructures              = 0
            allyKeyStructures           = 0
            allyGrp                     = allyGrp or CreateGroup()
            ForForce(allyTeam[playerIndex], locTable.structureCount.OnEnumAllyStructureCount)
        end

        ---Checks whether a player is crippled or not. Based on Blizzard's criteria,
        ---the player must still be active (not defeated) and have at least 1
        ---remaining allied structure.
        ---@param whichPlayer player
        ---@return boolean
        function locTable.structureCount.PlayerIsCrippled(whichPlayer)
            locTable.structureCount.EnumAllyStructureCount(whichPlayer)
            -- Dead teams are not considered to be crippled.
            return (allyStructures > 0) and (allyKeyStructures <= 0)
        end

        ---Returns the amount of allied structures left standing.
        ---@param whichPlayer player
        ---@return integer
        function locTable.structureCount.GetAllyStructureCount(whichPlayer)
            locTable.structureCount.EnumAllyStructureCount(whichPlayer)
            return allyStructures
        end

        ---Returns the amount of allied key structures left standing.
        ---@param whichPlayer player
        ---@return integer
        function locTable.structureCount.GetAllyKeyStructureCount(whichPlayer)
            locTable.structureCount.EnumAllyStructureCount(whichPlayer)
            return allyKeyStructures
        end
    end

    --  =============================================================================   --
    --                          Player Defeat API                                       --
    --  =============================================================================   --
    locTable.defeat             = {}
    do
        local defeatCheckPlayer = nil
        local defeatCurrPlayer  = nil

        ---This removes the locally defeated player from the list
        ---of enemy players.
        function locTable.defeat.OnDefeatRemove()
            local enumPlayer    = GetEnumPlayer()
            local index         = GetPlayerId(enumPlayer) + 1
            ForceRemovePlayer(enemyTeam[index], defeatCheckPlayer)
            ForceRemovePlayer(CustomRaceForce.activePlayers, defeatCheckPlayer)
            CustomRacePSelection.removeUnchoicedPlayer(enumPlayer)
            enemyCount[index]   = enemyCount[index] - 1
        end

        ---Iterate over all of the defeated player's enemies; remove it from
        ---their group of enemies.
        ---@param whichPlayer player
        function locTable.defeat.DefeatRemove(whichPlayer)
            local index             = GetPlayerId(whichPlayer)
            local prevPlayer        = defeatCheckPlayer
            defeatCheckPlayer       = whichPlayer
            ForForce(enemyTeam[index + 1], locTable.defeat.OnDefeatRemove)
            ForceClear(enemyTeam[index + 1])
            DestroyForce(enemyTeam[index + 1])
            enemyCount[index + 1]   = 0
            defeatCheckPlayer       = prevPlayer
        end

        ---Called whenever a player leaves the game (via ragequitting?)
        ---@param whichPlayer player
        function locTable.defeat.DoLeave(whichPlayer)
            local prevPlayer        = defeatCurrPlayer
            if (GetIntegerGameState(GAME_STATE_DISCONNECTED) ~= 0) then
                GameOverDialogBJ(whichPlayer, true )
                locTable.defeat.DefeatRemove(whichPlayer)
            else
                bj_meleeDefeated[GetPlayerId(whichPlayer)] = true
                locTable.defeat.DefeatRemove(whichPlayer)
                defeatCurrPlayer    = whichPlayer
                RemovePlayerPreserveUnitsBJ(whichPlayer, PLAYER_GAME_RESULT_DEFEAT, true)
                defeatCurrPlayer    = prevPlayer
            end
        end

        ---Called whenever a player is actually defeated (no allied structures remain)
        ---@param whichPlayer player
        function locTable.defeat.DoDefeat(whichPlayer)
            local index             = GetPlayerId(whichPlayer)
            local prevPlayer        = defeatCurrPlayer
            bj_meleeDefeated[index] = true
            locTable.defeat.DefeatRemove(whichPlayer)
            defeatCurrPlayer        = whichPlayer
            RemovePlayerPreserveUnitsBJ(whichPlayer, PLAYER_GAME_RESULT_DEFEAT, false)
            defeatCurrPlayer        = prevPlayer
        end
        function locTable.defeat.DoDefeatEnum()
            local thePlayer = GetEnumPlayer()

            -- needs to happen before ownership change
            locTable.surrender.TeamSurrender(thePlayer)
            locTable.defeat.DoDefeat(thePlayer)
        end

        -- Turns out, the ordinary version already does what I want to achieve with this
        -- resource, so I left it as is. I should probably just assign it directly to
        -- MeleeDoVictoryEnum though.
        DoVictoryEnum               = MeleeDoVictoryEnum or
        function()
            DoVictoryEnum           = MeleeDoVictoryEnum or DoVictoryEnum
            MeleeDoVictoryEnum()
        end
    end

    -- Hmm, I declared so many locals in this script. Perhaps I'll clean it up later.
    --  =============================================================================   --
    --                          Player Expose API                                       --
    --  =============================================================================   --
    locTable.expose                 = {}
    do
        local toExposeTo            = nil

        ---@param whichPlayer player
        ---@param expose boolean
        function locTable.expose.ExposePlayer(whichPlayer, expose)
            toExposeTo          = toExposeTo or CreateForce()
            local playerIndex   = GetPlayerId(whichPlayer) + 1
            CripplePlayer(whichPlayer, toExposeTo, false)
            bj_playerIsExposed[playerIndex - 1] = expose
            CripplePlayer(whichPlayer, enemyTeam[playerIndex], expose)
        end
        function locTable.expose.ExposeAllPlayers()
            local i = 1
            repeat
                locTable.expose.ExposePlayer(CustomRacePSelection._unchoiced[i], false)
                i = i + 1
            until (i > CustomRacePSelection.unchoicedPlayerSize)
        end
        function locTable.expose.RevealTimerTimeout()
            local expiredTimer  = GetExpiredTimer()
            local playerIndex   = 0
            local exposedPlayer
            -- Determine which player's timer expired.
            playerIndex = 0
            while (bj_crippledTimer[playerIndex] ~= expiredTimer) and
                  (playerIndex < bj_MAX_PLAYERS) do
                playerIndex = playerIndex + 1
            end
            if (playerIndex == bj_MAX_PLAYERS) then
                return
            end
            exposedPlayer       = Player(playerIndex)
            if (GetLocalPlayer() == exposedPlayer) then
                -- Hide the timer window for this player.
                TimerDialogDisplay(bj_crippledTimerWindows[playerIndex], false)
            end
            -- Display a text message to all players, explaining the exposure.
            DisplayTimedTextToPlayer(GetLocalPlayer(), 0, 0, bj_MELEE_CRIPPLE_MSG_DURATION, MeleeGetCrippledRevealedMessage(exposedPlayer))
            -- Expose the player.
            locTable.expose.ExposePlayer(exposedPlayer, true)
        end
    end

    --  =============================================================================   --
    --                      Victory and Defeat State Checkers                           --
    --  =============================================================================   --
    locTable.victory                        = {}
    do
        local tempForce
        local loserVictorCheckRecursive     = false

        ---Returns a force handle that contains the winning team if victory is already
        ---awarded, or none otherwise.
        ---@return force
        function locTable.victory.CheckForVictors()
            local playerIndex
            tempForce   = CreateForce()
            -- Check to see if any players have opponents remaining.
            playerIndex = 0
            while (playerIndex < bj_MAX_PLAYERS) do
                if (not bj_meleeDefeated[playerIndex]) then
                    -- Determine whether or not this player has any remaining opponents.
                    if enemyCount[playerIndex + 1] > 0 then
                        DestroyForce(tempForce)
                        -- Prevent an annoying warning here..
                        ---@diagnostic disable-next-line: return-type-mismatch
                        return nil
                    end
                    -- Keep track of each opponentless player so that we can give
                    -- them a victory later.
                    ForceAddPlayer(tempForce, Player(playerIndex))
                end
                playerIndex = playerIndex + 1
            end
            -- Set the game over global flag
            return tempForce
        end
        function locTable.victory.CheckForLosersAndVictors()
            local playerIndex
            local structureCount     = 0
            local indexPlayer
            local defeatedPlayers    = CreateForce()
            local victoriousPlayers
            local prevCheck          = loserVictorCheckRecursive

            -- If the game is already over, do nothing
            if (bj_meleeGameOver) then
                DestroyForce(defeatedPlayers)
                defeatedPlayers     = nil
                return
            end

            -- If the game was disconnected then it is over, in this case we
            -- don't want to report results for anyone as they will most likely
            -- conflict with the actual game results
            if (GetIntegerGameState(GAME_STATE_DISCONNECTED) ~= 0) then
                bj_meleeGameOver    = true
                DestroyForce(defeatedPlayers)
                defeatedPlayers     = nil
                return
            end

            -- Check each player to see if he or she has been defeated yet.
            playerIndex = 0
            while (playerIndex < bj_MAX_PLAYERS) do
                indexPlayer = Player(playerIndex)
                if (not bj_meleeDefeated[playerIndex] and not bj_meleeVictoried[playerIndex]) then
                    structureCount = locTable.structureCount.GetAllyStructureCount(indexPlayer)
                    if (structureCount <= 0) then
                        -- Keep track of each defeated player so that we can give
                        -- them a defeat later.
                        ForceAddPlayer(defeatedPlayers, Player(playerIndex))
                        -- Set their defeated flag now so MeleeCheckForVictors
                        -- can detect victors.
                        bj_meleeDefeated[playerIndex] = true
                    end
                end
                playerIndex = playerIndex + 1
            end
            -- Now that the defeated flags are set, check if there are any victors
            victoriousPlayers = locTable.victory.CheckForVictors()
            -- Defeat all defeated players
            ForForce(defeatedPlayers, locTable.defeat.DoDefeatEnum)
            -- Recheck victory conditions here
            if loserVictorCheckRecursive and (victoriousPlayers ~= nil) then
                bj_meleeGameOver    = true
                ForForce(victoriousPlayers, DoVictoryEnum)
                DestroyForce(victoriousPlayers)
                DestroyForce(defeatedPlayers)
                victoriousPlayers   = nil
                defeatedPlayers     = nil
                return
            end

            if (loserVictorCheckRecursive) then
                return
            end

            loserVictorCheckRecursive   = true
            locTable.victory.CheckForLosersAndVictors()
            loserVictorCheckRecursive   = prevCheck

            -- Give victory to all victorious players
            -- If the game is over we should remove all observers
            if (bj_meleeGameOver) then
                MeleeRemoveObservers()
            end
            DestroyForce(victoriousPlayers)
            DestroyForce(defeatedPlayers)
            defeatedPlayers     = nil
            victoriousPlayers   = nil
        end
    end

    --- Checks for any team whose number of key structures either fulfills the criteria for
    --- player crippling where it did not previously, and vice versa.
    function locTable.victory.CheckForCrippledPlayers()
        ---@type integer
        local playerIndex       = 0
        ---@type player
        local indexPlayer
        ---@type force
        local crippledPlayers   = CreateForce()
        ---@type boolean
        local isNowCrippled

        -- The "finish soon" exposure of all players overrides any "crippled" exposure
        if bj_finishSoonAllExposed then
            DestroyForce(crippledPlayers)
            crippledPlayers     = nil
            return
        end

        -- Check each player to see if he or she has been crippled or uncrippled.
        playerIndex = 0
        while (playerIndex < bj_MAX_PLAYERS) do
            indexPlayer     = Player(playerIndex)
            isNowCrippled   = locTable.structureCount.PlayerIsCrippled(indexPlayer)
            if (not bj_playerIsCrippled[playerIndex] and isNowCrippled) then
                -- Player became crippled; start their cripple timer.
                bj_playerIsCrippled[playerIndex] = true
                TimerStart(bj_crippledTimer[playerIndex], crippleTime, false, locTable.expose.RevealTimerTimeout)
                if (GetLocalPlayer() == indexPlayer) then
                    -- Use only local code (no net traffic) within this block to avoid desyncs.
                    -- Show the timer window.
                    TimerDialogDisplay(bj_crippledTimerWindows[playerIndex], true)
                    -- Display a warning message.
                end
                DisplayTimedTextToPlayer(indexPlayer, 0, 0, bj_MELEE_CRIPPLE_MSG_DURATION, MeleeGetCrippledWarningMessage(indexPlayer))

            elseif (bj_playerIsCrippled[playerIndex] and not isNowCrippled) then
                -- Player became uncrippled; stop their cripple timer.
                bj_playerIsCrippled[playerIndex] = false
                PauseTimer(bj_crippledTimer[playerIndex])
                if (GetLocalPlayer() == indexPlayer) then
                    -- Use only local code (no net traffic) within this block to avoid desyncs.
                    -- Hide the timer window for this player.
                    TimerDialogDisplay(bj_crippledTimerWindows[playerIndex], false)
                end
                -- Display a confirmation message if the player's team is still alive.
                if (locTable.structureCount.GetAllyStructureCount(indexPlayer) > 0) then
                    if (bj_playerIsExposed[playerIndex]) then
                        DisplayTimedTextToPlayer(indexPlayer, 0, 0, bj_MELEE_CRIPPLE_MSG_DURATION, GetLocalizedString("CRIPPLE_UNREVEALED"))
                    else
                        DisplayTimedTextToPlayer(indexPlayer, 0, 0, bj_MELEE_CRIPPLE_MSG_DURATION, GetLocalizedString("CRIPPLE_UNCRIPPLED"))
                    end
                end
                -- If the player granted shared vision, deny that vision now.
                locTable.expose.ExposePlayer(indexPlayer, false)
            end
            playerIndex = playerIndex + 1
        end
    end

    --  =============================================================================   --
    --                      Structure Count Updating functions                          --
    --  =============================================================================   --
    locTable.structureCheck         = {}
    ---Invoked whenever a structure is constructed.
    ---@param whichUnit unit
    function locTable.structureCheck.CheckAddedUnit(whichUnit)
        local owner = GetOwningPlayer(whichUnit)
        -- If the player was crippled, this unit may have uncrippled him/her.
        if (bj_playerIsCrippled[GetPlayerId(owner)]) then
            locTable.victory.CheckForCrippledPlayers()
        end
    end

    ---Invoked whenever a structure is destroyed.
    ---@param whichUnit unit
    function locTable.structureCheck.CheckLostUnit(whichUnit)
        local owner = GetOwningPlayer(whichUnit)
        local count = GetPlayerStructureCount(owner, true)
        -- We only need to check for mortality if this was the last building.
        if (count <= 0) then
            locTable.victory.CheckForLosersAndVictors()
        end
        -- Check if the lost unit has crippled or uncrippled the player.
        -- (A team with 0 units is dead, and thus considered uncrippled.)
        locTable.victory.CheckForCrippledPlayers()
    end

    --  =============================================================================   --
    --                          Player Event Related API                                --
    --  =============================================================================   --
    locTable.callback           = {}
    function locTable.callback.OnObserverLeave()
        ---@type player
        local thePlayer = GetTriggerPlayer()
        RemovePlayerPreserveUnitsBJ(thePlayer, PLAYER_GAME_RESULT_NEUTRAL, false)
    end

    ---Ported-over function from vJASS.
    ---@param flag boolean
    ---@param s1 string
    ---@param s2 string
    local function StrTertiaryOp(flag, s1, s2)
        return (flag and s1) or s2
    end

    ---Finally, another public function
    function locTable.callback.OnAllianceChange()
        ---@type player  
        local indexPlayer   = GetTriggerPlayer()
        ---@type player  
        local otherPlayer
        ---@type integer 
        local index         = GetPlayerId(indexPlayer)
        ---@type integer 
        local otherIndex    = 0

        --  Took too long to find this glaring bug, but it's finally fixed.
        --  Bug: indexPlayer is nil when this function is called directly
        --       and not because of an event, hence the need for indexPlayer
        --       to refer to CustomRaceForce.first in the first place.
        --       This bug resulted in PlayersAreCoAllied returning possible false
        --       negatives for Player 1.
        if (indexPlayer == nil) then
            indexPlayer = CustomRaceForce.first
            index       = GetPlayerId(indexPlayer)
        end
        while (otherIndex < bj_MAX_PLAYERS) do
            otherPlayer = Player(otherIndex)
            if (index == otherIndex) or (not locTable.playerState.WasPlayerActive(otherPlayer)) then
                -- continue
                goto OnAllianceChange__SKIP
            end
            if (BlzForceHasPlayer(allyTeam[index + 1], otherPlayer)) and 
                (not PlayersAreCoAllied(indexPlayer, otherPlayer)) then
                ForceRemovePlayer(allyTeam[index + 1], otherPlayer)
                ForceRemovePlayer(allyTeam[otherIndex + 1], indexPlayer)
                allyCount[index + 1]        = allyCount[index + 1] - 1
                allyCount[otherIndex + 1]   = allyCount[otherIndex + 1] - 1

                if (enemyCount[index + 1] > 0) and (enemyCount[otherIndex + 1] > 0) then
                    ForceAddPlayer(enemyTeam[index + 1], otherPlayer)
                    ForceAddPlayer(enemyTeam[otherIndex + 1], indexPlayer)
                    enemyCount[index + 1]       = enemyCount[index + 1] + 1
                    enemyCount[otherIndex + 1]  = enemyCount[otherIndex + 1] + 1
                end

                if controlShared[index] then
                    SetPlayerAlliance(indexPlayer, otherPlayer, ALLIANCE_SHARED_VISION, false)
                    SetPlayerAlliance(indexPlayer, otherPlayer, ALLIANCE_SHARED_CONTROL, false)
                    SetPlayerAlliance(otherPlayer, indexPlayer, ALLIANCE_SHARED_CONTROL, false)
                    SetPlayerAlliance(indexPlayer, otherPlayer, ALLIANCE_SHARED_ADVANCED_CONTROL, false)
                end

            elseif (BlzForceHasPlayer(enemyTeam[index + 1], otherPlayer)) and
                    (PlayersAreCoAllied(indexPlayer, otherPlayer)) then

                ForceRemovePlayer(enemyTeam[index + 1], otherPlayer)
                ForceRemovePlayer(enemyTeam[otherIndex + 1], indexPlayer)
                enemyCount[index + 1]       = enemyCount[index + 1] - 1
                enemyCount[otherIndex + 1]  = enemyCount[otherIndex + 1] - 1

                ForceAddPlayer(allyTeam[index + 1], otherPlayer)
                ForceAddPlayer(allyTeam[otherIndex + 1], indexPlayer)
                allyCount[index + 1]        = allyCount[index + 1] + 1
                allyCount[otherIndex + 1]   = allyCount[otherIndex + 1] + 1

                if controlShared[index] then
                    SetPlayerAlliance(indexPlayer, otherPlayer, ALLIANCE_SHARED_VISION, true)
                    SetPlayerAlliance(indexPlayer, otherPlayer, ALLIANCE_SHARED_CONTROL, true)
                    SetPlayerAlliance(otherPlayer, indexPlayer, ALLIANCE_SHARED_CONTROL, true)
                    SetPlayerAlliance(indexPlayer, otherPlayer, ALLIANCE_SHARED_ADVANCED_CONTROL, true)
                end
            end
            ::OnAllianceChange__SKIP::
            otherIndex  = otherIndex + 1
        end
        locTable.victory.CheckForLosersAndVictors()
        locTable.victory.CheckForCrippledPlayers()
    end
    _G[SCOPE_PREFIX .. "OnAllianceChange"]  = locTable.callback.OnAllianceChange

    function locTable.callback.OnPlayerLeave()
        ---@type player
        local thePlayer = GetTriggerPlayer()
        CachePlayerHeroData(thePlayer)

        -- This is the same as defeat except the player generates the message 
        -- "player left the game" as opposed to "player was defeated".
        if (locTable.structureCount.GetAllyCount(thePlayer) > 0) then
            -- If at least one ally is still alive and kicking, share units with
            -- them and proceed with death.
            locTable.teamControl.TeamShare(thePlayer)
            locTable.defeat.DoLeave(thePlayer)
        else
            -- If no living allies remain, swap all units and buildings over to
            -- neutral_passive and proceed with death.
            locTable.surrender.TeamSurrender(thePlayer)
            locTable.defeat.DoLeave(thePlayer)
        end
        locTable.victory.CheckForLosersAndVictors()
    end
    function locTable.callback.OnPlayerDefeat()
        ---@type player
        local thePlayer = GetTriggerPlayer()
        CachePlayerHeroData(thePlayer)
        --  Change it slightly so that control is automatically
        --  ceded to the computer.
        if (locTable.structureCount.GetAllyCount(thePlayer) > 0) then
            -- If at least one ally is still alive and kicking, share units with
            -- them and proceed with death.
            locTable.teamControl.TeamShare(thePlayer)
            if (not bj_meleeDefeated[GetPlayerId(thePlayer)]) then
                locTable.defeat.DoDefeat(thePlayer)
            end
        else
            -- If no living allies remain, swap all units and buildings over to
            -- neutral_passive and proceed with death.
            locTable.surrender.TeamSurrender(thePlayer)
            if (not bj_meleeDefeated[GetPlayerId(thePlayer)]) then
                locTable.defeat.DoDefeat(thePlayer)
            end
        end
        if defeatCurrPlayer == thePlayer then
            return
        end
        locTable.victory.CheckForLosersAndVictors()
    end
    function locTable.callback.OnConstructStart()
        locTable.structureCheck.CheckAddedUnit(GetConstructingStructure())
    end
    function locTable.callback.OnStructureDeath()
        ---@type unit
        local whichUnit    = GetTriggerUnit()
        if IsUnitType(whichUnit, UNIT_TYPE_STRUCTURE) then
            locTable.structureCheck.CheckLostUnit(whichUnit)
        end
    end
    function locTable.callback.OnConstructCancel()
        locTable.structureCheck.CheckLostUnit(GetTriggerUnit())
    end
    --  =============================================================================   --

    --  =============================================================================   --
    ---@param multiplier integer
    local function OnTournamentFinishRule(multiplier)
        local playerScore   = {}    -- integer
        local teamScore     = {}    -- integer
        local teamForce     = {}    -- force
        local teamCount     -- integer
        local indexPlayer   -- player
        local indexPlayer2  -- player
        local bestTeam      -- integer
        local bestScore     -- integer
        local draw          -- boolean

        -- Compute individual player scores
        for index = 0, bj_MAX_PLAYERS, 1 do
            indexPlayer = Player(index)
            if locTable.playerState.WasPlayerUser(indexPlayer) then
                playerScore[index] = IMinBJ(GetTournamentScore(indexPlayer), 1)
            else
                playerScore[index] = 0
            end
            index = index + 1
        end

        -- Compute team scores and team forces
        teamCount   = 0
        for index = 0, bj_MAX_PLAYERS - 1, 1 do
            if playerScore[index] ~= 0 then
                indexPlayer = Player(index)

                teamScore[teamCount] = 0
                teamForce[teamCount] = allyTeam[index + 1]

                for index2 = index, bj_MAX_PLAYERS - 1, 1 do
                    indexPlayer2    = Player(index2)
                    if not IsPlayerInForce(indexPlayer2, teamForce[teamCount]) then
                        goto skip_block
                    end
                    if playerScore[index2] ~= 0 then
                        teamScore[teamCount]    = teamScore[teamCount] + playerScore[index2]
                    end
                    ::skip_block::
                end
                teamCount = teamCount + 1
            end
        end

        -- The game is now over
        bj_meleeGameOver = true
        -- There should always be at least one team, but continue to work if not
        if teamCount ~= 0 then
            -- Find best team score
            bestTeam    = -1
            bestScore   = -1
            for index   = 0, teamCount, 1 do
                if teamScore[index] > bestScore then
                    bestTeam    = index
                    bestScore   = teamScore[index]
                end
            end
    
            -- Check whether the best team's score is 'multiplier' times better than
            -- every other team. In the case of multiplier == 1 and exactly equal team
            -- scores, the first team (which was randomly chosen by the server) will win.
            draw        = false
            for index   = 0, teamCount - 1, 1 do
                if (index ~= bestTeam) and
                   (bestScore < (multiplier * teamScore[index])) then
                    draw = true
                end
            end
            if draw then
                -- Give draw to all players on all teams
                for index   = 0, teamCount - 1, 1 do
                    ForForce(teamForce[index], MeleeDoDrawEnum)
                end
            else
                -- Give defeat to all players on teams other than the best team
                for index   = 0, teamCount - 1, 1 do
                    if index ~= bestTeam then
                        ForForce(teamForce[index], locTable.defeat.DoDefeatEnum)
                    end
                end
                -- Give victory to all players on the best team
                ForForce(teamForce[bestTeam], DoVictoryEnum)
            end
        end

        --  Might not actually be necessary.
        teamForce               = nil
        teamScore, playerScore  = nil, nil
    end
    local function OnTournamentFinishSoon()
        -- Note: We may get this trigger multiple times
        local indexPlayer   -- player
        local timeRemaining     = GetTournamentFinishSoonTimeRemaining()    -- number

        if bj_finishSoonAllExposed then
            return
        end
        bj_finishSoonAllExposed = true
        -- Reset all crippled players and their timers, and hide the local crippled timer dialog
        for playerIndex = 0, CustomRacePSelection.unchoicedPlayerSize, 1 do
            indexPlayer = CustomRacePSelection._unchoiced[playerIndex]
            locTable.expose.ExposePlayer(indexPlayer, false)
            --[[
            if bj_playerIsCrippled[playerIndex] then
                -- Uncripple the player
                bj_playerIsCrippled[playerIndex] = false
                PauseTimer(bj_crippledTimer[playerIndex])
    
                if (GetLocalPlayer() == indexPlayer) then
                    -- Use only local code (no net traffic) within this block to avoid desyncs.
                    -- Hide the timer window.
                    TimerDialogDisplay(bj_crippledTimerWindows[playerIndex], false)
                end
            end
            ]]
        end
        -- Expose all players
        locTable.expose.ExposeAllPlayers()

        -- Show the "finish soon" timer dialog and set the real time remaining
        TimerDialogDisplay(bj_finishSoonTimerDialog, true)
        TimerDialogSetRealTimeRemaining(bj_finishSoonTimerDialog, timeRemaining)
    end
    local function OnTournamentFinishNow()
        local rule = GetTournamentFinishNowRule()   -- integer
        -- If the game is already over, do nothing
        if bj_meleeGameOver then
            return
        end
        if (rule == 1) then
            -- Finals games
            OnTournamentFinishRule(1)
        else
            -- Preliminary games
            OnTournamentFinishRule(3)
        end
        -- Since the game is over we should remove all observers
        MeleeRemoveObservers()
    end
    --  =============================================================================   --

    --  =============================================================================   --
    locTable.teamLineup         = {}
    --- A helper function that sets up the configured ally and enemy forces
    --- for all players
    ---@param index integer
    ---@param otherIndex integer
    function locTable.teamLineup.DefineTeamLineupEx(index, otherIndex)
        local id                = index + 1         -- integer
        local otherID           = otherIndex + 1    -- integer
        local whichPlayer       = Player(index)     -- player
        local otherPlayer                           -- player

        --  One of the primary conditions for team lineup
        --  is that the player must be playing (obviously).
        activeOnStart[index]    = locTable.playerState.IsPlayerActive(whichPlayer)
        if not activeOnStart[index] then
            return
        end
        userOnStart[index]      = GetPlayerController(whichPlayer) == MAP_CONTROL_USER
        ForceAddPlayer(CustomRaceForce.activePlayers, whichPlayer)

        -- (not allyTeam[id]) works just as well, but this statement ensures that ambiguity is kept to a minimum.
        if allyTeam[id] == nil then
            allyTeam[id]        = CreateForce()
            allyCount[id]       = 1
            ForceAddPlayer(allyTeam[id], whichPlayer)
        end
        if enemyTeam[id] == nil then
            enemyTeam[id]       = CreateForce()
            enemyCount[id]      = 0
        end
        while (otherIndex < bj_MAX_PLAYERS) do
            otherPlayer     = Player(otherIndex)
            if locTable.playerState.IsPlayerActive(otherPlayer) then
                --  Instantiate the forces
                if allyTeam[otherID] == nil then
                    allyTeam[otherID]    = CreateForce()
                    allyCount[otherID]   = 1
                    ForceAddPlayer(allyTeam[otherID], otherPlayer)
                end
                if enemyTeam[otherID] == nil then
                    enemyTeam[otherID]   = CreateForce()
                    enemyCount[otherID]  = 0
                end
                if PlayersAreCoAllied(whichPlayer, otherPlayer) then
                    ForceAddPlayer(allyTeam[id], otherPlayer)
                    ForceAddPlayer(allyTeam[otherID], whichPlayer)
                    allyCount[id]       = allyCount[id] + 1
                    allyCount[otherID]  = allyCount[otherID] + 1
                else
                    ForceAddPlayer(enemyTeam[id], otherPlayer)
                    ForceAddPlayer(enemyTeam[otherID], whichPlayer)
                    enemyCount[id]      = enemyCount[id] + 1
                    enemyCount[otherID] = enemyCount[otherID] + 1
                end
            end
            otherIndex      = otherIndex + 1
            otherID         = otherIndex + 1
        end
    end
    function locTable.teamLineup.DefineTeamLineup()
        for index = 0, bj_MAX_PLAYERS - 1, 1 do
            locTable.teamLineup.DefineTeamLineupEx(index, index + 1)
        end
    end
    --  =============================================================================   --

    --  =============================================================================   --
    locTable.victoryDefeat          = {}
    function locTable.victoryDefeat.DefineVictoryDefeatEx()
        local constructCancelTrig   = CreateTrigger()   -- trigger 
        local deathTrig             = CreateTrigger()   -- trigger 
        local constructStartTrig    = CreateTrigger()   -- trigger 
        local defeatTrig            = CreateTrigger()   -- trigger 
        local leaveTrig             = CreateTrigger()   -- trigger 
        local allianceTrig          = CreateTrigger()   -- trigger 
        local obsLeaveTrig          = CreateTrigger()   -- trigger 
        local tournamentSoonTrig    = CreateTrigger()   -- trigger 
        local tournamentNowTrig     = CreateTrigger()   -- trigger 
        local indexPlayer                               -- player

        TriggerAddAction(constructCancelTrig, locTable.callback.OnConstructCancel)
        TriggerAddAction(deathTrig, locTable.callback.OnStructureDeath)
        TriggerAddAction(constructStartTrig, locTable.callback.OnConstructStart)
        TriggerAddAction(defeatTrig, locTable.callback.OnPlayerDefeat)
        TriggerAddAction(leaveTrig, locTable.callback.OnPlayerLeave)
        TriggerAddAction(allianceTrig, locTable.callback.OnAllianceChange)
        TriggerAddAction(obsLeaveTrig, locTable.callback.OnObserverLeave)
        TriggerAddAction(tournamentSoonTrig, OnTournamentFinishSoon)
        TriggerAddAction(tournamentNowTrig, OnTournamentFinishNow)

        -- Create a timer window for the "finish soon" timeout period, it has no timer
        -- because it is driven by real time (outside of the game state to avoid desyncs)
        bj_finishSoonTimerDialog = CreateTimerDialog(nil)

        -- Set a trigger to fire when we receive a "finish soon" game event
        TriggerRegisterGameEvent(tournamentSoonTrig, EVENT_GAME_TOURNAMENT_FINISH_SOON)
        -- Set a trigger to fire when we receive a "finish now" game event
        TriggerRegisterGameEvent(tournamentNowTrig, EVENT_GAME_TOURNAMENT_FINISH_NOW)
        -- Set up each player's mortality code.
        for index = 0, bj_MAX_PLAYERS - 1, 1 do
            indexPlayer = Player(index)

            -- Make sure this player slot is playing.
            if locTable.playerState.IsPlayerActive(indexPlayer) then
                bj_meleeDefeated[index]     = false
                bj_meleeVictoried[index]    = false

                --  Create a timer and timer window in case the player is crippled.
                --  Coder Notes: Better leave this section untouched.
                bj_playerIsCrippled[index]      = false
                bj_playerIsExposed[index]       = false
                bj_crippledTimer[index]         = CreateTimer()
                bj_crippledTimerWindows[index]  = CreateTimerDialog(bj_crippledTimer[index])
                TimerDialogSetTitle(bj_crippledTimerWindows[index], MeleeGetCrippledTimerMessage(indexPlayer))

                -- Set a trigger to fire whenever a building is cancelled for this player.
                TriggerRegisterPlayerUnitEvent(constructCancelTrig, indexPlayer, EVENT_PLAYER_UNIT_CONSTRUCT_CANCEL, nil)

                -- Set a trigger to fire whenever a unit dies for this player.
                TriggerRegisterPlayerUnitEvent(deathTrig, indexPlayer, EVENT_PLAYER_UNIT_DEATH, nil)

                -- Set a trigger to fire whenever a unit begins construction for this player
                TriggerRegisterPlayerUnitEvent(constructStartTrig, indexPlayer, EVENT_PLAYER_UNIT_CONSTRUCT_START, nil)

                -- Set a trigger to fire whenever this player defeats-out
                TriggerRegisterPlayerEvent(defeatTrig, indexPlayer, EVENT_PLAYER_DEFEAT)

                -- Set a trigger to fire whenever this player leaves
                TriggerRegisterPlayerEvent(leaveTrig, indexPlayer, EVENT_PLAYER_LEAVE)

                -- Set a trigger to fire whenever this player changes his/her alliances.
                TriggerRegisterPlayerAllianceChange(allianceTrig, indexPlayer, ALLIANCE_PASSIVE)
                TriggerRegisterPlayerStateEvent(allianceTrig, indexPlayer, PLAYER_STATE_ALLIED_VICTORY, EQUAL, 1)
            else
                bj_meleeDefeated[index]     = true
                bj_meleeVictoried[index]    = false
                -- Handle leave events for observers
                if (IsPlayerObserver(indexPlayer)) then
                    -- Set a trigger to fire whenever this player leaves
                    TriggerRegisterPlayerEvent(obsLeaveTrig, indexPlayer, EVENT_PLAYER_LEAVE)
                end
            end
        end
    end
    function locTable.victoryDefeat.DefineVictoryDefeat()
        --  I have no idea why I didn't just place the contents of DefineVictoryDefeatEx here
        --  in the first place.
        locTable.victoryDefeat.DefineVictoryDefeatEx()
    end
    _G[SCOPE_PREFIX .. "DefineVictoryDefeat"]   = locTable.victoryDefeat.DefineVictoryDefeat
    --  =============================================================================   --

    --  =============================================================================   --
    --                          Initializer Section                                     --
    --  =============================================================================   --
    if OnInit then
        OnInit.main(locTable.teamLineup.DefineTeamLineup)

    elseif AddHook then
        local removeHook, _;
        removeHook, _ = AddHook("SetMapMusic",
        function(musicPath, isRandom, index)
            --- Try using the old 5.1 Hooking mechanism.
            local status = pcall(function()
                SetMapMusic.old(musicPath, isRandom, index)
                locTable.teamLineup.DefineTeamLineup()
            end)
            if status then
                removeHook()
                removeHook, _   = nil, nil
                return
            end
            pcall(function()
                Hook.SetMapMusic(musicPath, isRandom, index)
                locTable.teamLineup.DefineTeamLineup()
            end)
            removeHook()
            removeHook, _   = nil, nil
        end)

    else
        local oldMapMusic   = SetMapMusic
        function SetMapMusic(...)
            locTable.teamLineup.DefineTeamLineup()
            SetMapMusic     = oldMapMusic
            oldMapMusic(...)
        end
    end

end