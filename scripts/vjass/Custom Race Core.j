library CustomRaceCore requires /*

    ----------------------
    */  Init,           /*
    ----------------------

    ----------------------
    */  optional Table  /*
    ----------------------
        - Bribe
        - link: https://www.hiveworkshop.com/threads/snippet-new-table.188084/


     ---------------------------------------------------------------------------------------
    |
    |   CustomRaceCore
    |       v.1.3
    |
    |---------------------------------------------------------------------------------------
    |
    |   The preliminary resource you'll ever want in modern techtree making (1.31+).
    |   Pros:
    |       - Custom UI for faction making.
    |       - Flexible faction creation.
    |       - Techtree display (with icon, name, and description).
    |       - Tournament-format compatibility.
    |       - (Observer) Real-time monitoring of player faction choice.
    |       - Up to 32767 factions in any game (realistically, 5 is really pushing it.)
    |
    |   Cons:
    |       - Available in versions 1.31 and above.
    |       - Requires CustomRaceFrame.fdf
    |
    |---------------------------------------------------------------------------------------
    |
    |   Since there are a lot of public methods in the CustomRace, it is
    |   to be assumed that every method found therein is considered to be
    |   a system only method, unless documented below:
    |       - static method create(race whichRace, name factionName) -> faction
    |           - Creates a new faction instance.
    |
    |       method defAISetup(code setupfunc)
    |           - Defines an AI setup function (just in case you would like
    |             to do more than just assign AI scripts).
    |       method defSetup(code setupfunc)
    |           - Defines a setup function. (This is usually when the hall
    |             and the workers are created).
    |       method defRacePic(string path)
    |           - Defines the race picture display. (Note: Empty String ""
    |             will show no race picture, while buggy paths will
    |             display a green box.)
    |       method defDescription(string desc)
    |           - Defines what the faction is all about. You can expand
    |             the lore of your faction here.
    |       method defName(string name)
    |           - Didn't like the original name? You can redefine it here.
    |       method defPlaylist(string playlist)
    |           - Defines a playlist that will play once the game
    |             officially starts (after faction choices have
    |             been made, setup has been performed, and the countdown finishes.)
    |
     ---------------------------------------------------------------------------------------
*/

struct CustomRace
    static if not LIBRARY_Table then
        private static hashtable ht     = InitHashtable()
        private static integer gHeroKey = 0
        private static integer gHallKey = 0
    else
        private static Table   gHeroMap = 0
        private static Table   gHallMap = 0
    endif

    readonly static integer array   globalHeroID
    readonly static integer array   globalHallID

    readonly static integer array   raceFactionCount
    readonly static thistype array  humanFactionObject
    readonly static thistype array  orcFactionObject
    readonly static thistype array  undeadFactionObject
    readonly static thistype array  nightelfFactionObject

    readonly string name
    readonly string racePic
    readonly string desc
    readonly string playlist
    readonly race   baseRace
    private trigger setupTrig
    private trigger setupTrigAI

    static if LIBRARY_Table then
        private Table hallTable
        private Table hallMap
        private Table heroTable
        private Table heroMap
        private Table unitTable
        private Table unitMap
        private Table strcTable
        private Table strcMap
    else
        private integer hallKey
        private integer hallMapKey
        private integer heroKey
        private integer heroMapKey
        private integer unitKey
        private integer unitMapKey
        private integer strcKey
        private integer strcMapKey
    endif

    static if not LIBRARY_Table then
    private static method generateKey takes nothing returns integer
        call SaveInteger(ht, 0, 0, LoadInteger(ht, 0, 0) + 1)
        return LoadInteger(ht, 0, 0)
    endmethod
    endif

    //  Only 4 races are actually available to the player.
    private static method isValidRace takes race whichRace returns boolean
        return GetHandleId(whichRace) < 5
    endmethod

    private static method updateFactionCount takes integer index, thistype this returns nothing
        set raceFactionCount[index]         = raceFactionCount[index] + 1
        if index == 1 then
            set humanFactionObject[raceFactionCount[index]] = this
        elseif index == 2 then
            set orcFactionObject[raceFactionCount[index]] = this
        elseif index == 3 then
            set undeadFactionObject[raceFactionCount[index]] = this
        elseif index == 4 then
            set nightelfFactionObject[raceFactionCount[index]] = this
        endif
    endmethod

    static method getRaceFactionCount takes race whichRace returns integer
        return raceFactionCount[GetHandleId(whichRace)]
    endmethod

    static method getRaceFaction takes race whichRace, integer index returns thistype
        local integer id = GetHandleId(whichRace)
        if (not thistype.isValidRace(whichRace)) then
            return thistype(-1)
        endif
        if id == 1 then
            return humanFactionObject[index]
        elseif id == 2 then
            return orcFactionObject[index]
        elseif id == 3 then
            return undeadFactionObject[index]
        endif
        return nightelfFactionObject[index]
    endmethod

    //  destroy method is reserved to prevent bugs from occurring related
    //  to the creation of factions at runtime.
    private method destroy takes nothing returns nothing
        call DisplayTimedTextToPlayer(GetLocalPlayer(), 0, 0, 60.00, /*
                                   */ "CustomRace.destroy >> Faction objects cannot be destroyed.")
    endmethod

    static method create takes race whichRace, string factionName returns thistype
        local thistype this = 0
        local integer index = GetHandleId(whichRace)
        if not thistype.isValidRace(whichRace) then
            return this
        endif
        set this            = thistype.allocate()
        set this.name       = factionName
        set this.baseRace   = whichRace
        //  Setting this to empty string ensures that the faction display frame
        //  will not show by default.
        set this.racePic    = ""
        //  Basic info about the race done, now create a Table instance
        static if LIBRARY_Table then
            set this.hallTable              = Table.create()
            set this.hallMap                = Table.create()
            set this.heroTable              = Table.create()
            set this.heroMap                = Table.create()
            set this.unitTable              = Table.create()
            set this.unitMap                = Table.create()
            set this.strcTable              = Table.create()
            set this.strcMap                = Table.create()
        else
            set this.hallKey                = generateKey()
            set this.hallMapKey             = generateKey()
            set this.heroKey                = generateKey()
            set this.heroMapKey             = generateKey()
            set this.unitKey                = generateKey()
            set this.unitMapKey             = generateKey()
            set this.strcKey                = generateKey()
            set this.strcMapKey             = generateKey()
        endif
        //  Update raceFactionCount and factionObject
        call thistype.updateFactionCount(index, this)
        return this
    endmethod

    //! textmacro CRCore_InstantiateStrings takes NAME
        call GetObjectName($NAME$)
        call BlzGetAbilityExtendedTooltip($NAME$, 0)
        call BlzGetAbilityIcon($NAME$)
    //! endtextmacro

    method addUnit takes integer unitID returns nothing
        //! runtextmacro CRCore_InstantiateStrings("unitID")
        static if LIBRARY_Table then
            if this.unitMap.has(unitID) then
                return
            endif
            set this.unitTable.integer[0]           = this.unitTable.integer[0] + 1
            set this.unitTable[this.unitTable[0]]   = unitID
            set this.unitMap[unitID]                = this.unitTable[0]
        else
            if HaveSavedInteger(ht, this.unitMapKey, unitID) then
                return
            endif
            call SaveInteger(ht, this.unitKey, 0, LoadInteger(ht, this.unitKey, 0) + 1)
            call SaveInteger(ht, this.unitKey, LoadInteger(ht, this.unitKey, 0), unitID)
            call SaveInteger(ht, this.unitMapKey, unitID, LoadInteger(ht, this.unitKey, 0))
        endif
    endmethod

    method addStructure takes integer strcID returns nothing
        //! runtextmacro CRCore_InstantiateStrings("strcID")
        static if LIBRARY_Table then
            if this.strcMap.has(strcID) then
                return
            endif
            set this.strcTable.integer[0]           = this.strcTable.integer[0] + 1
            set this.strcTable[this.strcTable[0]]   = strcID
            set this.strcMap[strcID]                = this.strcTable[0]
        else
            if HaveSavedInteger(ht, this.strcMapKey, strcID) then
                return
            endif
            call SaveInteger(ht, this.strcKey, 0, LoadInteger(ht, this.strcKey, 0) + 1)
            call SaveInteger(ht, this.strcKey, LoadInteger(ht, this.strcKey, 0), strcID)
            call SaveInteger(ht, this.strcMapKey, strcID, LoadInteger(ht, this.strcKey, 0))
        endif
    endmethod

    //  It is the responsibility of the user to provide the
    //  correct parameter for the heroIDs
    method addHero takes integer heroID returns nothing
        //! runtextmacro CRCore_InstantiateStrings("heroID")
        static if LIBRARY_Table then
            if this.heroMap.has(heroID) then
                return
            endif
            set this.heroTable.integer[0]           = this.heroTable.integer[0] + 1
            set this.heroTable[this.heroTable[0]]   = heroID
            set this.heroMap[heroID]                = this.heroTable[0]
            if gHeroMap.has(heroID) then
                return
            endif
            set globalHeroID[0]                     = globalHeroID[0] + 1
            set globalHeroID[globalHeroID[0]]       = heroID
            set gHeroMap[heroID]                    = globalHeroID[0]
        else
            if HaveSavedInteger(ht, this.heroMapKey, heroID) then
                return
            endif
            call SaveInteger(ht, this.heroKey, 0, LoadInteger(ht, this.heroKey, 0) + 1)
            call SaveInteger(ht, this.heroKey, LoadInteger(ht, this.heroKey, 0), heroID)
            call SaveInteger(ht, this.heroMapKey, heroID, LoadInteger(ht, this.heroKey, 0))
            if HaveSavedInteger(ht, gHeroKey, heroID) then
                return
            endif
            set globalHeroID[0]                     = globalHeroID[0] + 1
            set globalHeroID[globalHeroID[0]]       = heroID
            call SaveInteger(ht, gHeroKey, heroID, globalHeroID[0])
        endif
    endmethod

    method addHall takes integer hallID returns nothing
        //! runtextmacro CRCore_InstantiateStrings("hallID")
        static if LIBRARY_Table then
            if this.hallMap.has(hallID) then
                return
            endif
            set this.hallTable.integer[0]           = this.hallTable.integer[0] + 1
            set this.hallTable[this.hallTable[0]]   = hallID
            set this.hallMap[hallID]                = this.hallTable[0]
            if gHallMap.has(hallID) then
                return
            endif
            set globalHallID[0]                     = globalHallID[0] + 1
            set globalHallID[globalHallID[0]]       = hallID
            set gHallMap[hallID]                    = globalHallID[0]
        else
            if HaveSavedInteger(ht, this.hallMapKey, hallID) then
                return
            endif
            call SaveInteger(ht, this.hallKey, 0, LoadInteger(ht, this.hallKey, 0) + 1)
            call SaveInteger(ht, this.hallKey, LoadInteger(ht, this.hallKey, 0), hallID)
            call SaveInteger(ht, this.hallMapKey, hallID, LoadInteger(ht, this.hallKey, 0))
            if HaveSavedInteger(ht, gHallKey, hallID) then
                return
            endif
            set globalHallID[0]                     = globalHallID[0] + 1
            set globalHallID[globalHallID[0]]       = hallID
            call SaveInteger(ht, gHallKey, hallID, globalHallID[0])
        endif
    endmethod

    //! textmacro CRCore_DEF_GETTER takes NAME, SUBNAME
    method get$NAME$ takes integer index returns integer
        static if LIBRARY_Table then
            return this.$SUBNAME$Table[index]
        else
            return LoadInteger(ht, this.$SUBNAME$Key, index)
        endif
    endmethod

    method get$NAME$MaxIndex takes nothing returns integer
        static if LIBRARY_Table then
            return this.$SUBNAME$Table.integer[0]
        else
            return LoadInteger(ht, this.$SUBNAME$Key, 0)
        endif
    endmethod
    //! endtextmacro

    //! runtextmacro CRCore_DEF_GETTER("Hero", "hero")
    //! runtextmacro CRCore_DEF_GETTER("Hall", "hall")
    //! runtextmacro CRCore_DEF_GETTER("Unit", "unit")
    //! runtextmacro CRCore_DEF_GETTER("Structure", "strc")

    method getRandomHero takes nothing returns integer
        return this.getHero(GetRandomInt(1, this.getHeroMaxIndex()))
    endmethod
    
    static method getGlobalHeroMaxIndex takes nothing returns integer
        return globalHeroID[0]
    endmethod
    
    static method getGlobalHallMaxIndex takes nothing returns integer
        return globalHallID[0]
    endmethod

    static method getGlobalHero takes integer index returns integer
        return globalHeroID[index]
    endmethod

    static method getGlobalHall takes integer index returns integer
        return globalHallID[index]
    endmethod
    
    static method isGlobalHero takes integer heroID returns boolean
        static if LIBRARY_Table then
            return gHeroMap.has(heroID)
        else
            return HaveSavedInteger(ht, gHeroKey, heroID)
        endif
    endmethod

    static method addGlobalHero takes integer heroID returns nothing
        //! runtextmacro CRCore_InstantiateStrings("heroID")
        static if LIBRARY_Table then
            if gHeroMap.has(heroID) then
                return
            endif
            set globalHeroID[0]                     = globalHeroID[0] + 1
            set globalHeroID[globalHeroID[0]]       = heroID
            set gHeroMap[heroID]                    = globalHeroID[0]
        else
            if HaveSavedInteger(ht, gHeroKey, heroID) then
                return
            endif
            set globalHeroID[0]                     = globalHeroID[0] + 1
            set globalHeroID[globalHeroID[0]]       = heroID
            call SaveInteger(ht, gHeroKey, heroID, globalHeroID[0])
        endif
    endmethod

    static method addGlobalHall takes integer hallID returns nothing
        //! runtextmacro CRCore_InstantiateStrings("hallID")
        static if LIBRARY_Table then
            if gHeroMap.has(hallID) then
                return
            endif
            set globalHeroID[0]                     = globalHeroID[0] + 1
            set globalHeroID[globalHeroID[0]]       = hallID
            set gHeroMap[hallID]                    = globalHeroID[0]
        else
            if HaveSavedInteger(ht, gHeroKey, hallID) then
                return
            endif
            set globalHeroID[0]                     = globalHeroID[0] + 1
            set globalHeroID[globalHeroID[0]]       = hallID
            call SaveInteger(ht, gHeroKey, hallID, globalHeroID[0])
        endif
    endmethod

    static method isKeyStructure takes integer hallID returns boolean
        static if LIBRARY_Table then
            return gHallMap.has(hallID)
        else
            return HaveSavedInteger(ht, gHallKey, hallID)
        endif
    endmethod

    method defSetup takes code setupfunc returns nothing
        if this.setupTrig != null then
            call DestroyTrigger(this.setupTrig)
        endif
        set this.setupTrig      = CreateTrigger()
        call TriggerAddCondition(this.setupTrig, Condition(setupfunc))
    endmethod

    method defAISetup takes code setupfunc returns nothing
        if this.setupTrigAI != null then
            call DestroyTrigger(this.setupTrigAI)
        endif
        set this.setupTrigAI    = CreateTrigger()
        call TriggerAddCondition(this.setupTrigAI, Condition(setupfunc))
    endmethod
    method defRacePic takes string racePic returns nothing
        set this.racePic        = racePic
    endmethod
    method defDescription takes string desc returns nothing
        set this.desc           = desc
    endmethod
    method defName takes string name returns nothing
        set this.name           = name
    endmethod
    method defPlaylist takes string plist returns nothing
        set this.playlist       = plist
    endmethod

    method execSetup takes nothing returns nothing
        call TriggerEvaluate(this.setupTrig)
    endmethod
    method execSetupAI takes nothing returns nothing
        call TriggerEvaluate(this.setupTrigAI)
    endmethod

    private static method init takes nothing returns nothing
        set raceFactionCount[GetHandleId(RACE_HUMAN)]       = 0
        set raceFactionCount[GetHandleId(RACE_ORC)]         = 0
        set raceFactionCount[GetHandleId(RACE_UNDEAD)]      = 0
        set raceFactionCount[GetHandleId(RACE_NIGHTELF)]    = 0
        static if LIBRARY_Table then
            set gHeroMap                                    = Table.create()
            set gHallMap                                    = Table.create()
        else
            set gHeroKey                                    = generateKey()
            set gHallKey                                    = generateKey()
        endif
    endmethod
    implement Init
endstruct

endlibrary
