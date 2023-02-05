//$ noimport
library CustomRaceTemplate requires /*

    ----------------------
    */  CustomRaceCore, /*
    ----------------------

    ------------------------------
    */  CustomRacePSelection,   /*
    ------------------------------

    --------------------------
    */  CustomRaceMatch,    /*
    --------------------------
*/

globals
    private constant boolean IMPORTED_GUI_VARIABLES = true
    private constant integer MAX_LOC_AUTO_CLEANUP   = 20
endglobals

module CustomRaceTemplate
    //  private static race   FACTION_RACE
    //  private static string FACTION_NAME
    //  private static string FACTION_DESCRIPTION
    //  private static string FACTION_DISPLAY
    //  private static string FACTION_PLAYLIST

    //  private static integer FACTION_HALL
    //  private static integer FACTION_WORKER
    private static CustomRace faction   = 0

    static if not thistype.onSetup.exists then
    private static method onSetup takes player whichPlayer, location startLoc, boolean doHeroes, boolean doCamera, boolean doPreload returns nothing
        local boolean  useRandomHero    = IsMapFlagSet(MAP_RANDOM_HERO)
        local real     unitSpacing      = 64.00
        local unit     nearestMine
        local unit     randomHero
        local location mineLoc
        local location nearMineLoc
        local location heroLoc
        local real     peonX
        local real     peonY
        local unit     townHall         = null

        static if thistype.preloadPld.exists then
        if (doPreload) then
            call thistype.preloadPld()
        endif
        endif

        set nearestMine = MeleeFindNearestMine(startLoc, bj_MELEE_MINE_SEARCH_RADIUS)
        static if thistype.onSetupCreateUnits.exists then
            call thistype.onSetupCreateUnits(whichPlayer, nearestMine, startLoc)
        else
            if (nearestMine != null) then
                // Spawn Town Hall at the start location.
                set townHall = CreateUnitAtLoc(whichPlayer, FACTION_HALL, startLoc, bj_UNIT_FACING)
                
                // Spawn Peasants near the mine.
                set mineLoc     = GetUnitLoc(nearestMine)
                set nearMineLoc = MeleeGetProjectedLoc(mineLoc, startLoc, 320, 0)
                set peonX = GetLocationX(nearMineLoc)
                set peonY = GetLocationY(nearMineLoc)
                call CreateUnit(whichPlayer, FACTION_WORKER, peonX + 0.00 * unitSpacing, peonY + 1.00 * unitSpacing, bj_UNIT_FACING)
                call CreateUnit(whichPlayer, FACTION_WORKER, peonX + 1.00 * unitSpacing, peonY + 0.15 * unitSpacing, bj_UNIT_FACING)
                call CreateUnit(whichPlayer, FACTION_WORKER, peonX - 1.00 * unitSpacing, peonY + 0.15 * unitSpacing, bj_UNIT_FACING)
                call CreateUnit(whichPlayer, FACTION_WORKER, peonX + 0.60 * unitSpacing, peonY - 1.00 * unitSpacing, bj_UNIT_FACING)
                call CreateUnit(whichPlayer, FACTION_WORKER, peonX - 0.60 * unitSpacing, peonY - 1.00 * unitSpacing, bj_UNIT_FACING)
                call RemoveLocation(nearMineLoc)

                // Set random hero spawn point to be off to the side of the start location.
                set heroLoc = MeleeGetProjectedLoc(mineLoc, startLoc, 384, 45)
                call RemoveLocation(mineLoc)
            else
                // Spawn Town Hall at the start location.
                set townHall = CreateUnitAtLoc(whichPlayer, FACTION_HALL, startLoc, bj_UNIT_FACING)
                
                // Spawn Peasants directly south of the town hall.
                set peonX = GetLocationX(startLoc)
                set peonY = GetLocationY(startLoc) - 224.00
                call CreateUnit(whichPlayer, FACTION_WORKER, peonX + 2.00 * unitSpacing, peonY + 0.00 * unitSpacing, bj_UNIT_FACING)
                call CreateUnit(whichPlayer, FACTION_WORKER, peonX + 1.00 * unitSpacing, peonY + 0.00 * unitSpacing, bj_UNIT_FACING)
                call CreateUnit(whichPlayer, FACTION_WORKER, peonX + 0.00 * unitSpacing, peonY + 0.00 * unitSpacing, bj_UNIT_FACING)
                call CreateUnit(whichPlayer, FACTION_WORKER, peonX - 1.00 * unitSpacing, peonY + 0.00 * unitSpacing, bj_UNIT_FACING)
                call CreateUnit(whichPlayer, FACTION_WORKER, peonX - 2.00 * unitSpacing, peonY + 0.00 * unitSpacing, bj_UNIT_FACING)

                // Set random hero spawn point to be just south of the start location.
                // (Sorry, got lazy here.)
                set heroLoc = Location(peonX, peonY - 2.00 * unitSpacing)
            endif
            static if thistype.initTownhall.exists then
                call thistype.initTownhall(whichPlayer, townHall)
            endif
        endif

        if (doHeroes) then
            // If the "Random Hero" option is set, start the player with a random hero.
            // Otherwise, give them a "free hero" token.
            if useRandomHero then
                set randomHero  = CreateUnit(whichPlayer, faction.getRandomHero(), GetLocationX(heroLoc), GetLocationY(heroLoc), bj_UNIT_FACING)
                if bj_meleeGrantHeroItems then
                    call MeleeGrantItemsToHero(randomHero)
                endif
                set randomHero  = null
            else
                call SetPlayerState(whichPlayer, PLAYER_STATE_RESOURCE_HERO_TOKENS, bj_MELEE_STARTING_HERO_TOKENS)
            endif
        endif
        call RemoveLocation(heroLoc)

        if (doCamera) then
            // Center the camera on the initial Peasants.
            call SetCameraPositionForPlayer(whichPlayer, peonX, peonY)
            call SetCameraQuickPositionForPlayer(whichPlayer, peonX, peonY)
        endif
        set nearestMine = null
        set randomHero  = null
        set mineLoc     = null
        set nearMineLoc = null
        set heroLoc     = null
    endmethod
    endif

    private static method onSetupPrep takes nothing returns nothing
        call thistype.onSetup(CustomRaceMatch_OnStartGetPlayer(), /*
                           */ CustomRaceMatch_OnStartGetLoc(), true, true, true)
    endmethod

    private static method onSetupPrepAI takes nothing returns nothing
    static if thistype.onSetupAI.exists then
        call thistype.onSetupAI(CustomRaceMatch_OnStartGetPlayer())
    endif
    endmethod

    private static method onInit takes nothing returns nothing
        set faction = CustomRace.create(FACTION_RACE, FACTION_NAME)
        if faction == 0 then
            return
        endif
        call faction.defDescription(FACTION_DESCRIPTION)
        call faction.defRacePic(FACTION_DISPLAY)
        call faction.defPlaylist(FACTION_PLAYLIST)
        static if thistype.initTechtree.exists then
            call thistype.initTechtree(faction)
        endif
        call faction.defSetup(function thistype.onSetupPrep)
        call faction.defAISetup(function thistype.onSetupPrepAI)
    endmethod
endmodule

static if IMPORTED_GUI_VARIABLES then
struct CustomRaceTemplateGUI
    readonly CustomRace faction
    trigger setupTrig
    trigger setupTrigAI
    trigger preloadTrig
    integer factionHall
    integer factionWorker

    private static thistype array factionMap

    static if not thistype.onSetup.exists then
    private static method onSetup takes player whichPlayer, location startLoc, boolean doHeroes, boolean doCamera, boolean doPreload returns nothing
        local boolean  useRandomHero    = IsMapFlagSet(MAP_RANDOM_HERO)
        local real     unitSpacing      = 64.00
        local unit     nearestMine
        local unit     randomHero
        local location nearMineLoc
        local location heroLoc
        local real     peonX
        local real     peonY
        local real     mineAngle
        local unit     townHall         = null
        local CustomRacePSelection obj  = CRPSelection[whichPlayer]
        local CustomRace faction        = CustomRace.getRaceFaction(GetPlayerRace(whichPlayer), obj.faction)
        local thistype   this           = factionMap[faction]
        local integer    iter           = 0

        if (doPreload) then
            set udg_CustomRace_Player       = whichPlayer
            call ConditionalTriggerExecute(this.preloadTrig)
        endif

        set nearestMine = MeleeFindNearestMine(startLoc, bj_MELEE_MINE_SEARCH_RADIUS)
        if setupTrig != null then
            //  Introduce GUI Constants here
            set udg_CustomRace_Player                   = whichPlayer
            set udg_CustomRace_StartLocation            = startLoc
            set udg_CustomRace_PlayerMine               = nearestMine
            if (nearestMine != null) then
                set mineAngle   = Atan2(GetUnitY(nearestMine) - GetLocationY(startLoc), /*
                                     */ GetUnitX(nearestMine) - GetLocationX(startLoc))
                set udg_CustomRace_StartPeonCenterLoc   = Location(GetLocationX(startLoc) + 320*Cos(mineAngle), /*
                                                                */ GetLocationY(startLoc) + 320*Sin(mineAngle))
            else
                set udg_CustomRace_StartPeonCenterLoc   = Location(GetLocationX(startLoc), /*
                                                                */ GetLocationY(startLoc) - 224.0)
            endif
            call ConditionalTriggerExecute(this.setupTrig)
            loop
                //  MAX_LOC_AUTO_CLEANUP (20) seems more than reasonable enough for automatic location handle clean up.
                //  All indices higher than or equal to MAX_LOC_AUTO_CLEANUP should be cleaned up by the user himself.
                exitwhen ((iter > MAX_LOC_AUTO_CLEANUP) and (udg_CustomRace_StartPeonLoc[iter] == null))
                if (udg_CustomRace_StartPeonLoc[iter] != null) then
                    call RemoveLocation(udg_CustomRace_StartPeonLoc[iter])
                endif
                set udg_CustomRace_StartPeonLoc[iter]   = null
                set iter    = iter + 1
            endloop
            call RemoveLocation(udg_CustomRace_StartPeonCenterLoc)
            set udg_CustomRace_StartPeonCenterLoc       = null
            set udg_CustomRace_StartLocation            = null
        else
            if (nearestMine != null) then
                // Spawn Town Hall at the start location.
                set townHall    = CreateUnitAtLoc(whichPlayer, this.factionHall, startLoc, bj_UNIT_FACING)
                
                // Spawn Peasants near the mine.
                set mineAngle   = Atan2(GetUnitY(nearestMine) - GetLocationY(startLoc), /*
                                     */ GetUnitX(nearestMine) - GetLocationX(startLoc))
                set peonX       = GetLocationX(startLoc) + 320*Cos(mineAngle)
                set peonY       = GetLocationY(startLoc) + 320*Sin(mineAngle)
                call CreateUnit(whichPlayer, this.factionWorker, peonX + 0.00 * unitSpacing, peonY + 1.00 * unitSpacing, bj_UNIT_FACING)
                call CreateUnit(whichPlayer, this.factionWorker, peonX + 1.00 * unitSpacing, peonY + 0.15 * unitSpacing, bj_UNIT_FACING)
                call CreateUnit(whichPlayer, this.factionWorker, peonX - 1.00 * unitSpacing, peonY + 0.15 * unitSpacing, bj_UNIT_FACING)
                call CreateUnit(whichPlayer, this.factionWorker, peonX + 0.60 * unitSpacing, peonY - 1.00 * unitSpacing, bj_UNIT_FACING)
                call CreateUnit(whichPlayer, this.factionWorker, peonX - 0.60 * unitSpacing, peonY - 1.00 * unitSpacing, bj_UNIT_FACING)

                // Set random hero spawn point to be off to the side of the start location.
                set mineAngle   = mineAngle + bj_PI / 4.0
                set heroLoc     = Location(GetLocationX(startLoc) + 384*Cos(mineAngle), /*
                                        */ GetLocationY(startLoc) + 384*Sin(mineAngle))
            else
                // Spawn Town Hall at the start location.
                set townHall = CreateUnitAtLoc(whichPlayer, this.factionHall, startLoc, bj_UNIT_FACING)
                
                // Spawn Peasants directly south of the town hall.
                set peonX = GetLocationX(startLoc)
                set peonY = GetLocationY(startLoc) - 224.00
                call CreateUnit(whichPlayer, this.factionWorker, peonX + 2.00 * unitSpacing, peonY + 0.00 * unitSpacing, bj_UNIT_FACING)
                call CreateUnit(whichPlayer, this.factionWorker, peonX + 1.00 * unitSpacing, peonY + 0.00 * unitSpacing, bj_UNIT_FACING)
                call CreateUnit(whichPlayer, this.factionWorker, peonX + 0.00 * unitSpacing, peonY + 0.00 * unitSpacing, bj_UNIT_FACING)
                call CreateUnit(whichPlayer, this.factionWorker, peonX - 1.00 * unitSpacing, peonY + 0.00 * unitSpacing, bj_UNIT_FACING)
                call CreateUnit(whichPlayer, this.factionWorker, peonX - 2.00 * unitSpacing, peonY + 0.00 * unitSpacing, bj_UNIT_FACING)

                // Set random hero spawn point to be just south of the start location.
                set heroLoc = Location(peonX, peonY - 2.00 * unitSpacing)
            endif
        endif

        if (doHeroes) then
            // If the "Random Hero" option is set, start the player with a random hero.
            // Otherwise, give them a "free hero" token.
            if useRandomHero then
                set randomHero  = CreateUnit(whichPlayer, faction.getRandomHero(), GetLocationX(heroLoc), GetLocationY(heroLoc), bj_UNIT_FACING)
                if bj_meleeGrantHeroItems then
                    call MeleeGrantItemsToHero(randomHero)
                endif
                set randomHero  = null
            else
                call SetPlayerState(whichPlayer, PLAYER_STATE_RESOURCE_HERO_TOKENS, bj_MELEE_STARTING_HERO_TOKENS)
            endif
        endif
        call RemoveLocation(heroLoc)

        if (doCamera) then
            // Center the camera on the initial Peasants.
            call SetCameraPositionForPlayer(whichPlayer, peonX, peonY)
            call SetCameraQuickPositionForPlayer(whichPlayer, peonX, peonY)
        endif
        set nearestMine = null
        set randomHero  = null
        set nearMineLoc = null
        set heroLoc     = null
    endmethod
    endif

    private static method onSetupPrep takes nothing returns nothing
        call thistype.onSetup(CustomRaceMatch_OnStartGetPlayer(), /*
                           */ CustomRaceMatch_OnStartGetLoc(), true, true, true)
    endmethod

    private static method onSetupPrepAI takes nothing returns nothing
        local player whichPlayer        = CustomRaceMatch_OnStartGetPlayer()
        local CustomRacePSelection obj  = CRPSelection[whichPlayer]
        local CustomRace faction        = CustomRace.getRaceFaction(GetPlayerRace(whichPlayer), obj.faction)
        local thistype   this           = factionMap[faction]
        set udg_CustomRace_Player       = whichPlayer
        call ConditionalTriggerExecute(this.setupTrigAI)
    endmethod

    static method create takes race whichRace, string whichName returns thistype
        local thistype this = thistype.allocate()
        set this.faction    = CustomRace.create(whichRace, whichName)
        if this.faction == 0 then
            call this.deallocate()
            return 0
        endif
        set factionMap[this.faction]    = this
        call this.faction.defSetup(function thistype.onSetupPrep)
        call this.faction.defAISetup(function thistype.onSetupPrepAI)
        return this
    endmethod
endstruct

public function Create takes nothing returns nothing
    local CustomRaceTemplateGUI template    = CustomRaceTemplateGUI.create(udg_CustomRace_DefRace, udg_CustomRace_DefName)
    local integer i                         = 1
    call template.faction.defDescription(udg_CustomRace_Description)
    call template.faction.defRacePic(udg_CustomRace_Display)
    call template.faction.defPlaylist(udg_CustomRace_Playlist)
    set udg_CustomRace_DefRace          = null
    set udg_CustomRace_DefName          = ""
    set udg_CustomRace_Description      = ""
    set udg_CustomRace_Display          = ""
    set udg_CustomRace_Playlist         = ""

    set template.setupTrig              = udg_CustomRace_SetupTrig
    set template.setupTrigAI            = udg_CustomRace_AISetupTrig
    set template.preloadTrig            = udg_CustomRace_PreloadPLDTrig
    set udg_CustomRace_SetupTrig        = null
    set udg_CustomRace_AISetupTrig      = null
    set udg_CustomRace_PreloadPLDTrig   = null

    set template.factionHall            = udg_CustomRace_FactionHall
    set template.factionWorker          = udg_CustomRace_FactionWorker
    set udg_CustomRace_FactionHall      = 0
    set udg_CustomRace_FactionWorker    = 0
    //  Add all units
    loop
        exitwhen udg_CustomRace_UnitID[i] == 0
        call template.faction.addUnit(udg_CustomRace_UnitID[i])
        set udg_CustomRace_UnitID[i]    = 0
        set i = i + 1
    endloop
    //  Add all Heroes
    set i   = 1
    loop
        exitwhen udg_CustomRace_HeroID[i] == 0
        call template.faction.addHero(udg_CustomRace_HeroID[i])
        set udg_CustomRace_HeroID[i]    = 0
        set i = i + 1
    endloop
    //  Add all Halls
    set i   = 1
    loop
        exitwhen udg_CustomRace_HallID[i] == 0
        call template.faction.addHall(udg_CustomRace_HallID[i])
        set udg_CustomRace_HallID[i]    = 0
        set i = i + 1
    endloop
    //  Add all Structures
    set i   = 1
    loop
        exitwhen udg_CustomRace_BuildingID[i] == 0
        call template.faction.addStructure(udg_CustomRace_BuildingID[i])
        set udg_CustomRace_BuildingID[i]    = 0
        set i = i + 1
    endloop
endfunction
endif

endlibrary
