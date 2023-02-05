library CustomRaceMatchConditions requires /*

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
*/

native UnitAlive takes unit id returns boolean

globals
    private force array allyTeam
    private force array enemyTeam
    private integer array allyCount
    private integer array enemyCount
    private boolean array userOnStart
    private boolean array activeOnStart
    private boolean array controlShared
    private real crippleTime            = bj_MELEE_CRIPPLE_TIMEOUT
    private integer reqDebug            = 1
endglobals

struct CustomRaceForce extends array
    readonly static force activePlayers = CreateForce()
    readonly static player firstPlayer  = null

    private static method getFirst takes nothing returns nothing
        if firstPlayer != null then
            return
        endif
        set firstPlayer = GetEnumPlayer()
    endmethod

    static method operator first takes nothing returns player
        set firstPlayer = null
        call ForForce(activePlayers, function thistype.getFirst)
        return firstPlayer
    endmethod
endstruct

//  =============================================================================   //
public  function IsPlayerActive takes player whichPlayer returns boolean
    return (GetPlayerSlotState(whichPlayer) == PLAYER_SLOT_STATE_PLAYING) and /*
        */ (not IsPlayerObserver(whichPlayer))
endfunction
private function WasPlayerActive takes player whichPlayer returns boolean
    return activeOnStart[GetPlayerId(whichPlayer)]
endfunction
private function WasPlayerUser takes player whichPlayer returns boolean
    return WasPlayerActive(whichPlayer) and /*
        */ userOnStart[GetPlayerId(whichPlayer)]
endfunction
private function IsPlayerOpponent takes integer id, integer opID returns boolean
    local player thePlayer      = Player(id)
    local player theOpponent    = Player(opID)
    // The player himself is not an opponent.
    // Players that aren't playing aren't opponents.
    // Neither are players that are already defeated.
    if (id == opID) or /*
    */ (GetPlayerSlotState(theOpponent) != PLAYER_SLOT_STATE_PLAYING) or /*
    */ (bj_meleeDefeated[opID]) then
        //  Clean up reference leaks
        set thePlayer           = null
        set theOpponent         = null
        return false
    endif
    // Allied players with allied victory set are not opponents.
    if (GetPlayerAlliance(thePlayer, theOpponent, ALLIANCE_PASSIVE)) and /*
    */ (GetPlayerAlliance(theOpponent, thePlayer, ALLIANCE_PASSIVE)) and /*
    */ (GetPlayerState(thePlayer, PLAYER_STATE_ALLIED_VICTORY) == 1) and /*
    */ (GetPlayerState(theOpponent, PLAYER_STATE_ALLIED_VICTORY) == 1) then
        set thePlayer           = null
        set theOpponent         = null
        return false
    endif
    set thePlayer           = null
    set theOpponent         = null
    return true
endfunction
//  =============================================================================   //

//  =============================================================================   //
private function UnitSurrender takes nothing returns nothing
    call SetUnitOwner(GetEnumUnit(), Player(bj_PLAYER_NEUTRAL_VICTIM), false)
endfunction
private function PlayerSurrender takes player whichPlayer returns nothing
    local group   playerUnits   = CreateGroup()
    call CachePlayerHeroData(whichPlayer)
    call GroupEnumUnitsOfPlayer(playerUnits, whichPlayer, null)
    call ForGroup(playerUnits, function UnitSurrender)
    call DestroyGroup(playerUnits)
    set playerUnits             = null
endfunction
private function TeamSurrenderEnum takes nothing returns nothing
    call PlayerSurrender(GetEnumPlayer())
endfunction
private function TeamSurrender takes player whichPlayer returns nothing
    local integer playerIndex   = GetPlayerId(whichPlayer) + 1
    call ForForce(allyTeam[playerIndex], function TeamSurrenderEnum)
endfunction
//  =============================================================================   //

//  =============================================================================   //
globals
    private player shareCheckPlayer     = null
endglobals
private function TeamGainControl takes nothing returns nothing
    local player enumPlayer = GetEnumPlayer()
    if (PlayersAreCoAllied(shareCheckPlayer, enumPlayer)) and /*
    */ (shareCheckPlayer != enumPlayer) then
        call SetPlayerAlliance(shareCheckPlayer, enumPlayer, ALLIANCE_SHARED_VISION, true)
        call SetPlayerAlliance(shareCheckPlayer, enumPlayer, ALLIANCE_SHARED_CONTROL, true)
        call SetPlayerAlliance(enumPlayer, shareCheckPlayer, ALLIANCE_SHARED_CONTROL, true)
        call SetPlayerAlliance(shareCheckPlayer, enumPlayer, ALLIANCE_SHARED_ADVANCED_CONTROL, true)
    endif
    set enumPlayer          = null
endfunction
private function TeamShare takes player whichPlayer returns nothing
    local integer       playerIndex     = GetPlayerId(whichPlayer) + 1
    local CustomRace    curFaction      = 0
    set curFaction                      = CustomRace.getRaceFaction(GetPlayerRace(whichPlayer), /*
                                                                 */ CRPSelection[whichPlayer].faction)
    set controlShared[playerIndex - 1]  = true
    set shareCheckPlayer                = whichPlayer
    call ForForce(allyTeam[playerIndex], function TeamGainControl)
    call SetPlayerController(whichPlayer, MAP_CONTROL_COMPUTER)
    call curFaction.execSetupAI()    
endfunction
//  =============================================================================   //

//  =============================================================================   //
globals
    private integer allyStructures          = 0
    private integer allyKeyStructures       = 0
    private integer allyCountEnum           = 0
    private player  checkPlayer             = null
    private constant group allyStructGroup  = CreateGroup()
endglobals
private function AllyCountEnum takes nothing returns nothing
    local player enumPlayer     = GetEnumPlayer()
    local integer playerIndex   = GetPlayerId(enumPlayer)
    if (not bj_meleeDefeated[playerIndex]) and /*
    */ (checkPlayer != enumPlayer) then
        set allyCountEnum = allyCountEnum + 1
    endif
endfunction
private function GetAllyCount takes player whichPlayer returns integer
    set allyCountEnum   = 0
    set checkPlayer     = whichPlayer
    call ForForce(allyTeam[GetPlayerId(whichPlayer) + 1], function AllyCountEnum)
    return allyCountEnum
endfunction
private function GetAllyKeyStructureCountEnum takes nothing returns boolean
    return UnitAlive(GetFilterUnit()) and /*
        */ CustomRace.isKeyStructure(GetUnitTypeId(GetFilterUnit()))
endfunction
private function OnEnumAllyStructureCount takes nothing returns nothing
    local player enumPlayer = GetEnumPlayer()

    call GroupEnumUnitsOfPlayer(allyStructGroup, enumPlayer, /*
                             */ Filter(function GetAllyKeyStructureCountEnum))
    set allyStructures      = allyStructures + GetPlayerStructureCount(enumPlayer, true)
    set allyKeyStructures   = allyKeyStructures + BlzGroupGetSize(allyStructGroup)
    set enumPlayer          = null
endfunction
private function EnumAllyStructureCount takes player whichPlayer returns nothing
    local integer    playerIndex    = GetPlayerId(whichPlayer) + 1
    set allyStructures              = 0
    set allyKeyStructures           = 0
    call ForForce(allyTeam[playerIndex], function OnEnumAllyStructureCount)
endfunction
private function PlayerIsCrippled takes player whichPlayer returns boolean
    call EnumAllyStructureCount(whichPlayer)
    // Dead teams are not considered to be crippled.
    return (allyStructures > 0) and (allyKeyStructures <= 0)
endfunction
private function GetAllyStructureCount takes player whichPlayer returns integer
    call EnumAllyStructureCount(whichPlayer)
    return allyStructures
endfunction
private function GetAllyKeyStructureCount takes player whichPlayer returns integer
    call EnumAllyStructureCount(whichPlayer)
    return allyKeyStructures
endfunction
//  =============================================================================   //

//  =============================================================================   //
globals
    private player  defeatCheckPlayer   = null
    private player  defeatCurrPlayer    = null
endglobals
//  This removes the locally defeated player from the list
//  of enemy players.
private function OnDefeatRemove takes nothing returns nothing
    local player enumPlayer = GetEnumPlayer()
    local integer index     = GetPlayerId(enumPlayer) + 1
    call ForceRemovePlayer(enemyTeam[index], defeatCheckPlayer)
    call ForceRemovePlayer(CustomRaceForce.activePlayers, defeatCheckPlayer)
    call CustomRacePSelection.removeUnchoicedPlayer(enumPlayer)
    set enemyCount[index]   = enemyCount[index] - 1
endfunction
private function DefeatRemove takes player whichPlayer returns nothing
    local integer index     = GetPlayerId(whichPlayer)
    local player prevPlayer = defeatCheckPlayer
    set defeatCheckPlayer   = whichPlayer
    call ForForce(enemyTeam[index + 1], function OnDefeatRemove)
    call ForceClear(enemyTeam[index + 1])
    call DestroyForce(enemyTeam[index + 1])
    set enemyCount[index + 1]   = 0
    set defeatCheckPlayer       = prevPlayer
endfunction
private function DoLeave takes player whichPlayer returns nothing
    local player prevPlayer     = defeatCurrPlayer
    if (GetIntegerGameState(GAME_STATE_DISCONNECTED) != 0) then
        call GameOverDialogBJ(whichPlayer, true )
        call DefeatRemove(whichPlayer)
    else
        set bj_meleeDefeated[GetPlayerId(whichPlayer)] = true
        call DefeatRemove(whichPlayer)
        set defeatCurrPlayer        = whichPlayer
        call RemovePlayerPreserveUnitsBJ(whichPlayer, PLAYER_GAME_RESULT_DEFEAT, true)
        set defeatCurrPlayer        = prevPlayer
    endif
endfunction
private function DoDefeat takes player whichPlayer returns nothing
    local integer index         = GetPlayerId(whichPlayer)
    local player prevPlayer     = defeatCurrPlayer
    set bj_meleeDefeated[index] = true
    call DefeatRemove(whichPlayer)
    set defeatCurrPlayer        = whichPlayer
    call RemovePlayerPreserveUnitsBJ(whichPlayer, PLAYER_GAME_RESULT_DEFEAT, false)
    set defeatCurrPlayer        = prevPlayer
endfunction
private function DoDefeatEnum takes nothing returns nothing
    local player thePlayer = GetEnumPlayer()

    // needs to happen before ownership change
    call TeamSurrender(thePlayer)
    call DoDefeat(thePlayer)
endfunction
private function DoVictoryEnum takes nothing returns nothing
    //  Diagnose problems with VictoryEnum
    call MeleeDoVictoryEnum()
endfunction
//  =============================================================================   //

//  =============================================================================   //
globals
    private constant force toExposeTo   = CreateForce()
endglobals
private function ExposePlayer takes player whichPlayer, boolean expose returns nothing
    local integer playerIndex   = GetPlayerId(whichPlayer) + 1
    call CripplePlayer(whichPlayer, toExposeTo, false)
    set bj_playerIsExposed[playerIndex - 1] = expose
    call CripplePlayer(whichPlayer, enemyTeam[playerIndex], expose)
endfunction
private function ExposeAllPlayers takes nothing returns nothing
    local integer i = 1
    loop
        exitwhen i > CustomRacePSelection.unchoicedPlayerSize
        call ExposePlayer(CustomRacePSelection.unchoicedPlayers[i], false)
        set i = i + 1
    endloop
endfunction
private function RevealTimerTimeout takes nothing returns nothing
    local timer expiredTimer    = GetExpiredTimer()
    local integer playerIndex   = 0
    local player  exposedPlayer
    // Determine which player's timer expired.
    set playerIndex = 0
    loop
        exitwhen (bj_crippledTimer[playerIndex] == expiredTimer) 
        set playerIndex = playerIndex + 1
        exitwhen playerIndex == bj_MAX_PLAYERS
    endloop
    if (playerIndex == bj_MAX_PLAYERS) then
        set expiredTimer        = null
        return
    endif
    set exposedPlayer = Player(playerIndex)
    if (GetLocalPlayer() == exposedPlayer) then
        // Hide the timer window for this player.
        call TimerDialogDisplay(bj_crippledTimerWindows[playerIndex], false)
    endif
    // Display a text message to all players, explaining the exposure.
    call DisplayTimedTextToPlayer(GetLocalPlayer(), 0, 0, bj_MELEE_CRIPPLE_MSG_DURATION, MeleeGetCrippledRevealedMessage(exposedPlayer))
    // Expose the player.
    call ExposePlayer(exposedPlayer, true)
    set expiredTimer        = null
endfunction
//  =============================================================================   //

//  =============================================================================   //
globals
    private force   tempForce
    private boolean loserVictorCheckRecursive   = false
endglobals
private function CheckForVictors takes nothing returns force
    local integer    playerIndex
    set tempForce   = CreateForce()
    // Check to see if any players have opponents remaining.
    set playerIndex = 0
    loop
        if (not bj_meleeDefeated[playerIndex]) then
            // Determine whether or not this player has any remaining opponents.
            if enemyCount[playerIndex + 1] > 0 then
                call DestroyForce(tempForce)
                return null
            endif
            // Keep track of each opponentless player so that we can give
            // them a victory later.
            call ForceAddPlayer(tempForce, Player(playerIndex))
        endif
        set playerIndex = playerIndex + 1
        exitwhen playerIndex == bj_MAX_PLAYERS
    endloop
    // Set the game over global flag
    return tempForce
endfunction
private function CheckForLosersAndVictors takes nothing returns nothing
    local integer    playerIndex
    local integer    structureCount     = 0
    local player     indexPlayer
    local force      defeatedPlayers    = CreateForce()
    local force      victoriousPlayers
    local boolean    prevCheck          = loserVictorCheckRecursive

    // If the game is already over, do nothing
    if (bj_meleeGameOver) then
        call DestroyForce(defeatedPlayers)
        set defeatedPlayers     = null
        return
    endif

    // If the game was disconnected then it is over, in this case we
    // don't want to report results for anyone as they will most likely
    // conflict with the actual game results
    if (GetIntegerGameState(GAME_STATE_DISCONNECTED) != 0) then
        set bj_meleeGameOver    = true
        call DestroyForce(defeatedPlayers)
        set defeatedPlayers     = null
        return
    endif

    // Check each player to see if he or she has been defeated yet.
    set playerIndex = 0
    loop
        set indexPlayer = Player(playerIndex)
        if (not bj_meleeDefeated[playerIndex] and not bj_meleeVictoried[playerIndex]) then
            set structureCount = GetAllyStructureCount(indexPlayer)
            if (structureCount <= 0) then
                // Keep track of each defeated player so that we can give
                // them a defeat later.
                call ForceAddPlayer(defeatedPlayers, Player(playerIndex))
                // Set their defeated flag now so MeleeCheckForVictors
                // can detect victors.
                set bj_meleeDefeated[playerIndex] = true
            endif
        endif
        set playerIndex = playerIndex + 1
        exitwhen playerIndex == bj_MAX_PLAYERS
    endloop
    // Now that the defeated flags are set, check if there are any victors
    set victoriousPlayers = CheckForVictors()
    // Defeat all defeated players
    call ForForce(defeatedPlayers, function DoDefeatEnum)
    // Recheck victory conditions here
    if loserVictorCheckRecursive then 
        if (victoriousPlayers != null) then
            set bj_meleeGameOver    = true
            call ForForce(victoriousPlayers, function DoVictoryEnum)
            call DestroyForce(victoriousPlayers)
        endif
        call DestroyForce(defeatedPlayers)
        set victoriousPlayers   = null
        set defeatedPlayers     = null
        return
    endif

    set loserVictorCheckRecursive   = true
    call CheckForLosersAndVictors()
    set loserVictorCheckRecursive   = prevCheck

    // Give victory to all victorious players
    // If the game is over we should remove all observers
    if (bj_meleeGameOver) then
        call MeleeRemoveObservers()
    endif
    call DestroyForce(victoriousPlayers)
    call DestroyForce(defeatedPlayers)
    set defeatedPlayers     = null
    set victoriousPlayers   = null
endfunction
private function CheckForCrippledPlayers takes nothing returns nothing
    local integer    playerIndex
    local player     indexPlayer
    local force      crippledPlayers = CreateForce()
    local boolean    isNowCrippled

    // The "finish soon" exposure of all players overrides any "crippled" exposure
    if bj_finishSoonAllExposed then
        call DestroyForce(crippledPlayers)
        set crippledPlayers = null
        return
    endif

    // Check each player to see if he or she has been crippled or uncrippled.
    set playerIndex = 0
    loop
        set indexPlayer     = Player(playerIndex)
        set isNowCrippled   = PlayerIsCrippled(indexPlayer)
        if (not bj_playerIsCrippled[playerIndex] and isNowCrippled) then
            // Player became crippled; start their cripple timer.
            set bj_playerIsCrippled[playerIndex] = true
            call TimerStart(bj_crippledTimer[playerIndex], crippleTime, false, function RevealTimerTimeout)
            if (GetLocalPlayer() == indexPlayer) then
                // Use only local code (no net traffic) within this block to avoid desyncs.
                // Show the timer window.
                call TimerDialogDisplay(bj_crippledTimerWindows[playerIndex], true)
                // Display a warning message.
            endif
            call DisplayTimedTextToPlayer(indexPlayer, 0, 0, bj_MELEE_CRIPPLE_MSG_DURATION, MeleeGetCrippledWarningMessage(indexPlayer))

        elseif (bj_playerIsCrippled[playerIndex] and not isNowCrippled) then
            // Player became uncrippled; stop their cripple timer.
            set bj_playerIsCrippled[playerIndex] = false
            call PauseTimer(bj_crippledTimer[playerIndex])
            if (GetLocalPlayer() == indexPlayer) then
                // Use only local code (no net traffic) within this block to avoid desyncs.
                // Hide the timer window for this player.
                call TimerDialogDisplay(bj_crippledTimerWindows[playerIndex], false)
            endif
            // Display a confirmation message if the player's team is still alive.
            if (GetAllyStructureCount(indexPlayer) > 0) then
                if (bj_playerIsExposed[playerIndex]) then
                    call DisplayTimedTextToPlayer(indexPlayer, 0, 0, bj_MELEE_CRIPPLE_MSG_DURATION, GetLocalizedString("CRIPPLE_UNREVEALED"))
                else
                    call DisplayTimedTextToPlayer(indexPlayer, 0, 0, bj_MELEE_CRIPPLE_MSG_DURATION, GetLocalizedString("CRIPPLE_UNCRIPPLED"))
                endif
            endif
            // If the player granted shared vision, deny that vision now.
            call ExposePlayer(indexPlayer, false)
        endif
        set playerIndex = playerIndex + 1
        exitwhen playerIndex == bj_MAX_PLAYERS
    endloop
    call DestroyForce(crippledPlayers)
    set crippledPlayers = null
endfunction
//  =============================================================================   //

//  =============================================================================   //
private function CheckAddedUnit takes unit whichUnit returns nothing
    local player owner = GetOwningPlayer(whichUnit)
    // If the player was crippled, this unit may have uncrippled him/her.
    if (bj_playerIsCrippled[GetPlayerId(owner)]) then
        call CheckForCrippledPlayers()
    endif
endfunction
private function CheckLostUnit takes unit whichUnit returns nothing
    local player owner  = GetOwningPlayer(whichUnit)
    local integer count = GetPlayerStructureCount(owner, true)
    // We only need to check for mortality if this was the last building.
    if (count <= 0) then
        call CheckForLosersAndVictors()
    endif
    // Check if the lost unit has crippled or uncrippled the player.
    // (A team with 0 units is dead, and thus considered uncrippled.)
    call CheckForCrippledPlayers()
endfunction
//  =============================================================================   //

//  =============================================================================   //
private function OnObserverLeave takes nothing returns nothing
    local player thePlayer = GetTriggerPlayer()
    call RemovePlayerPreserveUnitsBJ(thePlayer, PLAYER_GAME_RESULT_NEUTRAL, false)
endfunction
private function StrTertiaryOp takes boolean flag, string s1, string s2 returns string
    if flag then
        return s1
    endif
    return s2
endfunction
public  function OnAllianceChange takes nothing returns nothing
    local player  indexPlayer   = GetTriggerPlayer()
    local player  otherPlayer
    local integer index         = GetPlayerId(indexPlayer)
    local integer otherIndex    = 0

    //  Took too long to find this glaring bug, but it's finally fixed.
    //  Bug: indexPlayer is null when this function is called directly
    //       and not because of an event, hence the need for indexPlayer
    //       to refer to CustomRaceForce.first in the first place.
    //       This bug resulted in PlayersAreCoAllied returning possible false
    //       negatives for Player 1.
    if (indexPlayer == null) then
        set indexPlayer = CustomRaceForce.first
        set index       = GetPlayerId(indexPlayer)
    endif
    loop
        exitwhen otherIndex >= bj_MAX_PLAYERS
        set otherPlayer = Player(otherIndex)
        loop
            exitwhen (index == otherIndex) or (not WasPlayerActive(otherPlayer))
            if (BlzForceHasPlayer(allyTeam[index + 1], otherPlayer)) and /*
            */ (not PlayersAreCoAllied(indexPlayer, otherPlayer)) then
                call ForceRemovePlayer(allyTeam[index + 1], otherPlayer)
                call ForceRemovePlayer(allyTeam[otherIndex + 1], indexPlayer)
                set allyCount[index + 1]        = allyCount[index + 1] - 1
                set allyCount[otherIndex + 1]   = allyCount[otherIndex + 1] - 1

                if (enemyCount[index + 1] > 0) and (enemyCount[otherIndex + 1] > 0) then
                    call ForceAddPlayer(enemyTeam[index + 1], otherPlayer)
                    call ForceAddPlayer(enemyTeam[otherIndex + 1], indexPlayer)
                    set enemyCount[index + 1]       = enemyCount[index + 1] + 1
                    set enemyCount[otherIndex + 1]  = enemyCount[otherIndex + 1] + 1
                endif

                if controlShared[index] then
                    call SetPlayerAlliance(indexPlayer, otherPlayer, ALLIANCE_SHARED_VISION, false)
                    call SetPlayerAlliance(indexPlayer, otherPlayer, ALLIANCE_SHARED_CONTROL, false)
                    call SetPlayerAlliance(otherPlayer, indexPlayer, ALLIANCE_SHARED_CONTROL, false)
                    call SetPlayerAlliance(indexPlayer, otherPlayer, ALLIANCE_SHARED_ADVANCED_CONTROL, false)
                endif

            elseif (BlzForceHasPlayer(enemyTeam[index + 1], otherPlayer)) and /*
                */ (PlayersAreCoAllied(indexPlayer, otherPlayer)) then

                call ForceRemovePlayer(enemyTeam[index + 1], otherPlayer)
                call ForceRemovePlayer(enemyTeam[otherIndex + 1], indexPlayer)
                set enemyCount[index + 1]       = enemyCount[index + 1] - 1
                set enemyCount[otherIndex + 1]  = enemyCount[otherIndex + 1] - 1

                call ForceAddPlayer(allyTeam[index + 1], otherPlayer)
                call ForceAddPlayer(allyTeam[otherIndex + 1], indexPlayer)
                set allyCount[index + 1]        = allyCount[index + 1] + 1
                set allyCount[otherIndex + 1]   = allyCount[otherIndex + 1] + 1

                if controlShared[index] then
                    call SetPlayerAlliance(indexPlayer, otherPlayer, ALLIANCE_SHARED_VISION, true)
                    call SetPlayerAlliance(indexPlayer, otherPlayer, ALLIANCE_SHARED_CONTROL, true)
                    call SetPlayerAlliance(otherPlayer, indexPlayer, ALLIANCE_SHARED_CONTROL, true)
                    call SetPlayerAlliance(indexPlayer, otherPlayer, ALLIANCE_SHARED_ADVANCED_CONTROL, true)
                endif
            endif
            exitwhen true
        endloop
        set otherIndex  = otherIndex + 1
    endloop
    call CheckForLosersAndVictors()
    call CheckForCrippledPlayers()
endfunction
private function OnPlayerLeave takes nothing returns nothing
    local player thePlayer = GetTriggerPlayer()
    call CachePlayerHeroData(thePlayer)

    // This is the same as defeat except the player generates the message 
    // "player left the game" as opposed to "player was defeated".
    if (GetAllyCount(thePlayer) > 0) then
        // If at least one ally is still alive and kicking, share units with
        // them and proceed with death.
        call TeamShare(thePlayer)
        call DoLeave(thePlayer)
    else
        // If no living allies remain, swap all units and buildings over to
        // neutral_passive and proceed with death.
        call TeamSurrender(thePlayer)
        call DoLeave(thePlayer)
    endif
    call CheckForLosersAndVictors()
endfunction
private function OnPlayerDefeat takes nothing returns nothing
    local player thePlayer = GetTriggerPlayer()
    call CachePlayerHeroData(thePlayer)
    //  Change it slightly so that control is automatically
    //  ceded to the computer.
    if (GetAllyCount(thePlayer) > 0) then
        // If at least one ally is still alive and kicking, share units with
        // them and proceed with death.
        call TeamShare(thePlayer)
        if (not bj_meleeDefeated[GetPlayerId(thePlayer)]) then
            call DoDefeat(thePlayer)
        endif
    else
        // If no living allies remain, swap all units and buildings over to
        // neutral_passive and proceed with death.
        call TeamSurrender(thePlayer)
        if (not bj_meleeDefeated[GetPlayerId(thePlayer)]) then
            call DoDefeat(thePlayer)
        endif
    endif
    if defeatCurrPlayer == thePlayer then
        return
    endif
    call CheckForLosersAndVictors()
endfunction
private function OnConstructStart takes nothing returns nothing
    call CheckAddedUnit(GetConstructingStructure())
endfunction
private function OnStructureDeath takes nothing returns nothing
    local unit whichUnit    = GetTriggerUnit()
    if IsUnitType(whichUnit, UNIT_TYPE_STRUCTURE) then
        call CheckLostUnit(whichUnit)
    endif
    set whichUnit           = null
endfunction
private function OnConstructCancel takes nothing returns nothing
    call CheckLostUnit(GetTriggerUnit())
endfunction

//  =============================================================================   //
private function OnTournamentFinishRule takes integer multiplier returns nothing
    local integer array playerScore
    local integer array teamScore
    local force array   teamForce
    local integer       teamCount
    local integer       index
    local player        indexPlayer
    local integer       index2
    local player        indexPlayer2
    local integer       bestTeam
    local integer       bestScore
    local boolean       draw

    // Compute individual player scores
    set index = 0
    loop
        set indexPlayer = Player(index)
        if WasPlayerUser(indexPlayer) then
            set playerScore[index] = IMinBJ(GetTournamentScore(indexPlayer), 1)
        else
            set playerScore[index] = 0
        endif
        set index = index + 1
        exitwhen index == bj_MAX_PLAYERS
    endloop

    // Compute team scores and team forces
    set teamCount   = 0
    set index       = 0
    loop
        if playerScore[index] != 0 then
            set indexPlayer = Player(index)

            set teamScore[teamCount] = 0
            set teamForce[teamCount] = allyTeam[index + 1]

            set index2 = index
            loop
                loop
                    exitwhen not IsPlayerInForce(Player(index2), teamForce[teamCount])
                    if playerScore[index2] != 0 then
                        set indexPlayer2            = Player(index2)
                        set teamScore[teamCount]    = teamScore[teamCount] + playerScore[index2]
                    endif
                    exitwhen true
                endloop
                set index2 = index2 + 1
                exitwhen index2 == bj_MAX_PLAYERS
            endloop
            set teamCount = teamCount + 1
        endif

        set index = index + 1
        exitwhen index == bj_MAX_PLAYERS
    endloop

    // The game is now over
    set bj_meleeGameOver = true
    // There should always be at least one team, but continue to work if not
    if teamCount != 0 then
        // Find best team score
        set bestTeam    = -1
        set bestScore   = -1
        set index = 0
        loop
            if teamScore[index] > bestScore then
                set bestTeam    = index
                set bestScore   = teamScore[index]
            endif
            set index = index + 1
            exitwhen index == teamCount
        endloop

        // Check whether the best team's score is 'multiplier' times better than
        // every other team. In the case of multiplier == 1 and exactly equal team
        // scores, the first team (which was randomly chosen by the server) will win.
        set draw    = false
        set index   = 0
        loop
            if index != bestTeam then
                if bestScore < (multiplier * teamScore[index]) then
                    set draw = true
                endif
            endif
            set index = index + 1
            exitwhen index == teamCount
        endloop
        if draw then
            // Give draw to all players on all teams
            set index = 0
            loop
                call ForForce(teamForce[index], function MeleeDoDrawEnum)

                set index = index + 1
                exitwhen index == teamCount
            endloop
        else
            // Give defeat to all players on teams other than the best team
            set index = 0
            loop
                if index != bestTeam then
                    call ForForce(teamForce[index], function DoDefeatEnum)
                endif

                set index = index + 1
                exitwhen index == teamCount
            endloop

            // Give victory to all players on the best team
            call ForForce(teamForce[bestTeam], function DoVictoryEnum)
        endif
    endif

    //  Clean up leaks (Thanks to Karaulov's Jass Script Helper)
    set index           = 0
    loop
        exitwhen index == bj_MAX_PLAYERS
        set teamForce[index]    = null
        set index               = index + 1
    endloop
endfunction
private function OnTournamentFinishSoon takes nothing returns nothing
    // Note: We may get this trigger multiple times
    local integer    playerIndex
    local player     indexPlayer
    local real       timeRemaining = GetTournamentFinishSoonTimeRemaining()

    if bj_finishSoonAllExposed then
        return
    endif
    set bj_finishSoonAllExposed = true
    // Reset all crippled players and their timers, and hide the local crippled timer dialog
    set playerIndex = 0
    loop
        exitwhen playerIndex > CustomRacePSelection.unchoicedPlayerSize
        set indexPlayer = CustomRacePSelection.unchoicedPlayers[playerIndex]
        call ExposePlayer(indexPlayer, false)
        /*
        if bj_playerIsCrippled[playerIndex] then
            // Uncripple the player
            set bj_playerIsCrippled[playerIndex] = false
            call PauseTimer(bj_crippledTimer[playerIndex])

            if (GetLocalPlayer() == indexPlayer) then
                // Use only local code (no net traffic) within this block to avoid desyncs.
                // Hide the timer window.
                call TimerDialogDisplay(bj_crippledTimerWindows[playerIndex], false)
            endif
        endif
        */
        set playerIndex = playerIndex + 1
        exitwhen playerIndex == bj_MAX_PLAYERS
    endloop
    // Expose all players
    call ExposeAllPlayers()

    // Show the "finish soon" timer dialog and set the real time remaining
    call TimerDialogDisplay(bj_finishSoonTimerDialog, true)
    call TimerDialogSetRealTimeRemaining(bj_finishSoonTimerDialog, timeRemaining)
endfunction
private function OnTournamentFinishNow takes nothing returns nothing
    local integer rule = GetTournamentFinishNowRule()
    // If the game is already over, do nothing
    if bj_meleeGameOver then
        return
    endif
    if (rule == 1) then
        // Finals games
        call MeleeTournamentFinishNowRuleA(1)
    else
        // Preliminary games
        call MeleeTournamentFinishNowRuleA(3)
    endif
    // Since the game is over we should remove all observers
    call MeleeRemoveObservers()
endfunction
//  =============================================================================   //

//  =============================================================================   //
private function DefineTeamLineupEx takes integer index, integer otherIndex returns nothing
    local integer id            = index + 1
    local integer otherID       = otherIndex + 1
    local player  whichPlayer   = Player(index)
    local player  otherPlayer
    //  One of the primary conditions for team lineup
    //  is that the player must be playing (obviously).
    set activeOnStart[index]    = IsPlayerActive(whichPlayer)
    if not activeOnStart[index] then
        return
    endif
    set userOnStart[index]      = GetPlayerController(whichPlayer) == MAP_CONTROL_USER
    call ForceAddPlayer(CustomRaceForce.activePlayers, whichPlayer)
    if allyTeam[id] == null then
        set allyTeam[id]    = CreateForce()
        set allyCount[id]   = 1
        call ForceAddPlayer(allyTeam[id], whichPlayer)
    endif
    if enemyTeam[id] == null then
        set enemyTeam[id]   = CreateForce()
        set enemyCount[id]  = 0
    endif
    loop
        exitwhen otherIndex >= bj_MAX_PLAYERS
        set otherPlayer     = Player(otherIndex)
        if IsPlayerActive(otherPlayer) then
            //  Instantiate the forces
            if allyTeam[otherID] == null then
                set allyTeam[otherID]    = CreateForce()
                set allyCount[otherID]   = 1
                call ForceAddPlayer(allyTeam[otherID], otherPlayer)
            endif
            if enemyTeam[otherID] == null then
                set enemyTeam[otherID]   = CreateForce()
                set enemyCount[otherID]  = 0
            endif
            if PlayersAreCoAllied(whichPlayer, otherPlayer) then
                call ForceAddPlayer(allyTeam[id], otherPlayer)
                call ForceAddPlayer(allyTeam[otherID], whichPlayer)
                set allyCount[id]       = allyCount[id] + 1
                set allyCount[otherID]  = allyCount[otherID] + 1
            else
                call ForceAddPlayer(enemyTeam[id], otherPlayer)
                call ForceAddPlayer(enemyTeam[otherID], whichPlayer)
                set enemyCount[id]      = enemyCount[id] + 1
                set enemyCount[otherID] = enemyCount[otherID] + 1
            endif
        endif
        set otherIndex      = otherIndex + 1
        set otherID         = otherIndex + 1
    endloop
endfunction
private function DefineTeamLineup takes nothing returns nothing
    local integer index         = 0
    local integer otherIndex    = 0
    loop
        exitwhen index >= bj_MAX_PLAYERS
        set otherIndex  = index + 1
        call DefineTeamLineupEx(index, otherIndex)
        set index       = index + 1
    endloop
endfunction
private function DefineVictoryDefeatEx takes nothing returns nothing
    local trigger constructCancelTrig   = CreateTrigger()
    local trigger deathTrig             = CreateTrigger()
    local trigger constructStartTrig    = CreateTrigger()
    local trigger defeatTrig            = CreateTrigger()
    local trigger leaveTrig             = CreateTrigger()
    local trigger allianceTrig          = CreateTrigger()
    local trigger obsLeaveTrig          = CreateTrigger()
    local trigger tournamentSoonTrig    = CreateTrigger()
    local trigger tournamentNowTrig     = CreateTrigger()
    local integer index
    local player  indexPlayer

    call TriggerAddAction(constructCancelTrig, function OnConstructCancel)
    call TriggerAddAction(deathTrig, function OnStructureDeath)
    call TriggerAddAction(constructStartTrig, function OnConstructStart)
    call TriggerAddAction(defeatTrig, function OnPlayerDefeat)
    call TriggerAddAction(leaveTrig, function OnPlayerLeave)
    call TriggerAddAction(allianceTrig, function OnAllianceChange)
    call TriggerAddAction(obsLeaveTrig, function OnObserverLeave)
    call TriggerAddAction(tournamentSoonTrig, function OnTournamentFinishSoon)
    call TriggerAddAction(tournamentNowTrig, function OnTournamentFinishNow)


    // Create a timer window for the "finish soon" timeout period, it has no timer
    // because it is driven by real time (outside of the game state to avoid desyncs)
    set bj_finishSoonTimerDialog = CreateTimerDialog(null)

    // Set a trigger to fire when we receive a "finish soon" game event
    call TriggerRegisterGameEvent(tournamentSoonTrig, EVENT_GAME_TOURNAMENT_FINISH_SOON)
    // Set a trigger to fire when we receive a "finish now" game event
    call TriggerRegisterGameEvent(tournamentNowTrig, EVENT_GAME_TOURNAMENT_FINISH_NOW)
    // Set up each player's mortality code.
    set index = 0
    loop
        set indexPlayer = Player(index)

        // Make sure this player slot is playing.
        if IsPlayerActive(indexPlayer) then
            set bj_meleeDefeated[index]     = false
            set bj_meleeVictoried[index]    = false

            //  Create a timer and timer window in case the player is crippled.
            //  Coder Notes: Better leave this section untouched.
            set bj_playerIsCrippled[index]      = false
            set bj_playerIsExposed[index]       = false
            set bj_crippledTimer[index]         = CreateTimer()
            set bj_crippledTimerWindows[index]  = CreateTimerDialog(bj_crippledTimer[index])
            call TimerDialogSetTitle(bj_crippledTimerWindows[index], /*
                                  */ MeleeGetCrippledTimerMessage(indexPlayer))

            // Set a trigger to fire whenever a building is cancelled for this player.
            call TriggerRegisterPlayerUnitEvent(constructCancelTrig, indexPlayer, /*
                                             */ EVENT_PLAYER_UNIT_CONSTRUCT_CANCEL, null)

            // Set a trigger to fire whenever a unit dies for this player.
            call TriggerRegisterPlayerUnitEvent(deathTrig, indexPlayer, /*
                                             */ EVENT_PLAYER_UNIT_DEATH, null)

            // Set a trigger to fire whenever a unit begins construction for this player
            call TriggerRegisterPlayerUnitEvent(constructStartTrig, indexPlayer, /*
                                             */ EVENT_PLAYER_UNIT_CONSTRUCT_START, null)

            // Set a trigger to fire whenever this player defeats-out
            call TriggerRegisterPlayerEvent(defeatTrig, indexPlayer, EVENT_PLAYER_DEFEAT)

            // Set a trigger to fire whenever this player leaves
            call TriggerRegisterPlayerEvent(leaveTrig, indexPlayer, EVENT_PLAYER_LEAVE)

            // Set a trigger to fire whenever this player changes his/her alliances.
            call TriggerRegisterPlayerAllianceChange(allianceTrig, indexPlayer, ALLIANCE_PASSIVE)
            call TriggerRegisterPlayerStateEvent(allianceTrig, indexPlayer, PLAYER_STATE_ALLIED_VICTORY, EQUAL, 1)
        else
            set bj_meleeDefeated[index]     = true
            set bj_meleeVictoried[index]    = false
            // Handle leave events for observers
            if (IsPlayerObserver(indexPlayer)) then
                // Set a trigger to fire whenever this player leaves
                call TriggerRegisterPlayerEvent(obsLeaveTrig, indexPlayer, EVENT_PLAYER_LEAVE)
            endif
        endif

        set index = index + 1
        exitwhen index == bj_MAX_PLAYERS
    endloop
endfunction
public  function DefineVictoryDefeat takes nothing returns nothing
    //  I have no idea why I didn't just place the contents of DefineVictoryDefeatEx here
    //  in the first place.
    call DefineVictoryDefeatEx()
endfunction
//  =============================================================================   //

private struct S extends array
    private static method init takes nothing returns nothing
        call DefineTeamLineup()
    endmethod
    implement Init
endstruct

endlibrary