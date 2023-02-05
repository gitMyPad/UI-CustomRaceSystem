library CustomRacePSelection requires /*

    ----------------------
    */  CustomRaceCore, /*
    ----------------------

    ----------------------
    */  CustomRaceUI,   /*
    ----------------------

    ----------------------
    */  Init,           /*
    ----------------------

     ---------------------------------------------------------------------------------------
    |
    |  This library is intended to handle the selection of
    |  players who can select certain factions in addition
    |  to the regular races.
    |
    |---------------------------------------------------------------------------------------
    |
    |   As an additional note, this library dictates whether
    |   Computer Units get to use custom factions or not via
    |   COMP_CUSTOM_FACTION (previously ComputerPlayersUseCustomFaction())
    |
     ---------------------------------------------------------------------------------------
*/

globals
    private constant boolean COMP_CUSTOM_FACTION    = true
endglobals

struct CustomRacePSelection extends array
    readonly integer raceIndex
    readonly static boolean isSinglePlayer          = false
    private  static integer userPlayerCount         = 0

    integer faction

    integer baseChoice
    integer focusFaction
    integer focusFactionStack

    static  integer array   baseTechID
    integer techtree
    integer focusTechtree
    integer focusTechtreeStack
    integer focusTechID

    readonly static integer choicedPlayerSize       = 0
    readonly static integer unchoicedPlayerSize     = 0
    readonly static player  array choicedPlayers
    readonly static player  array unchoicedPlayers
    private  static integer array choicedPlayerMap
    private  static integer array unchoicedPlayerMap

    static method operator [] takes integer index returns thistype
        return thistype(index + 1)
    endmethod

    method getBaseTechID takes integer index returns integer
        return baseTechID[(integer(this)-1)*CustomRaceUI_GetTechtreeChunkCount() + index]
    endmethod

    method setBaseTechID takes integer index, integer value returns nothing
        set baseTechID[(integer(this)-1)*CustomRaceUI_GetTechtreeChunkCount() + index] = value
    endmethod

    //! textmacro_once CRPSelect_ADD_REMOVE takes NAME, SUBNAME
    static method add$NAME$Player takes player p returns boolean
        local integer id        = GetPlayerId(p) + 1
        if $SUBNAME$PlayerMap[id] != 0 then
            return false
        endif
        set $SUBNAME$PlayerSize                   = $SUBNAME$PlayerSize + 1
        set $SUBNAME$Players[$SUBNAME$PlayerSize] = p
        set $SUBNAME$PlayerMap[id]                = 1
        return true
    endmethod

    static method remove$NAME$Player takes player p returns boolean
        local integer id        = GetPlayerId(p) + 1
        local integer i         = 1
        if $SUBNAME$PlayerMap[id] == 0 then
            return false
        endif
        loop
            //  The second condition is unnecessary, but
            //  I want to make sure it really stops at
            //  that point. If it does, I have a bug to fix.
            exitwhen ($SUBNAME$Players[i] == p) or (i > $SUBNAME$PlayerSize)
            set i = i + 1
        endloop
        //  Note: The distinction between id and i
        //  id refers to the player's ID + 1
        //  i refers to the position of the player in the array in question.
        set $SUBNAME$Players[i]                   = $SUBNAME$Players[$SUBNAME$PlayerSize]
        set $SUBNAME$Players[$SUBNAME$PlayerSize] = null
        set $SUBNAME$PlayerSize                   = $SUBNAME$PlayerSize - 1
        set $SUBNAME$PlayerMap[id]                = 0
        return true
    endmethod

    static method has$NAME$Player takes player p returns boolean
        return $SUBNAME$PlayerMap[GetPlayerId(p) + 1] != 0
    endmethod
    //! endtextmacro

    // Looking back, these given method names are quite strange.
    //! runtextmacro CRPSelect_ADD_REMOVE("Choiced", "choiced")
    //! runtextmacro CRPSelect_ADD_REMOVE("Unchoiced", "unchoiced")

    //  This initializing static method is invoked in CustomRaceUserUI.
    static method init takes nothing returns nothing
        local integer i         = 0
        local player p          = null
        local race r            = null
        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS - 4
            set p                       = Player(i)
            set r                       = GetPlayerRace(p)
            set thistype[i].raceIndex   = GetHandleId(r)
            //  For string synchronization purposes.
            call GetPlayerName(p)
            if (GetPlayerController(p) == MAP_CONTROL_USER) and /*
            */ (GetPlayerSlotState(p)  == PLAYER_SLOT_STATE_PLAYING) then
                set userPlayerCount     = userPlayerCount + 1
                if (CustomRace.getRaceFactionCount(r) > 1) then
                    call thistype.addChoicedPlayer(p)
                else
                    set thistype[i].faction = 1
                    call thistype.addUnchoicedPlayer(p)
                endif

            elseif (GetPlayerSlotState(p) == PLAYER_SLOT_STATE_PLAYING) then
                static if COMP_CUSTOM_FACTION then
                    set thistype[i].faction = GetRandomInt(1, CustomRace.getRaceFactionCount(r))
                else
                    set thistype[i].faction = 1
                endif
                call thistype.addUnchoicedPlayer(p)
            endif
            set i = i + 1
        endloop
        set isSinglePlayer  = (userPlayerCount == 1)
        set p               = null
        set r               = null
    endmethod
endstruct

struct CRPSelection extends array
    static method [] takes player p returns CustomRacePSelection
        return CustomRacePSelection[GetPlayerId(p)]
    endmethod
endstruct

endlibrary