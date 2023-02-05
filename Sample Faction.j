//$ noimport
scope NewFaction

//  Sample Faction
private struct SampleFaction extends array
    private static race   FACTION_RACE          = RACE_HUMAN
    private static string FACTION_NAME          = "High Elves"
    private static string FACTION_DISPLAY       = ""
    private static string FACTION_PLAYLIST      = "Sound\\Music\\mp3Music\\NagaTheme.mp3;Sound\\Music\\mp3Music\\BloodElfTheme.mp3;Sound\\Music\\mp3Music\\Human1.mp3"

    private static integer FACTION_HALL         = 'h000'
    private static integer FACTION_WORKER       = 'n000'
    private static string FACTION_DESCRIPTION   = "Humans, but more advanced in magic."

    /*
    //  If you prefer creative control over how the player units
    //  are created, you can implement this function.
    private static method onSetupCreateUnits takes player whichPlayer, unit mine returns nothing
    endmethod
    */

    /*
    //  When a computer player uses a different faction, it might
    //  want to use a different script. You can use this function to
    //  specify the ai script it will use.
    private static method onSetupAI takes player whichPlayer returns nothing
    endmethod
    */

    /*
    //  I'm not entirely sure what this function is supposed to do.
    //  Maybe it might be useful to you?
    private static method preloadPld takes nothing returns nothing
        call Preloader("scripts\\HumanMelee.pld")
    endmethod
    */

    private static method initTechtree takes CustomRace faction returns nothing
        call faction.addUnit('n000')
        call faction.addUnit('h001')
        call faction.addUnit('n002')
        
        call faction.addHall('h000')

        call faction.addStructure('h000')
        call faction.addStructure('n003')
        call faction.addStructure('n001')
        call faction.addStructure('h003')
        call faction.addStructure('h002')
        call faction.addStructure('n004')
    endmethod

    implement CustomRaceTemplate
endstruct

endscope