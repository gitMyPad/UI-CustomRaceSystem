//$ noimport
library CustomRaceDefault requires /*

    ----------------------
    */  CustomRaceCore, /*
    ----------------------

    --------------------------
    */  CustomRaceMatch,    /*
    --------------------------

    ----------------------
    */  Init,           /*
    ----------------------

*/

globals
    private CustomRace array defaultRace
endglobals

//! textmacro CRDefault_DEF_SETUP takes NAME, SUBNAME
private function On$NAME$Setup takes nothing returns nothing
    call MeleeStartingUnits$NAME$(CustomRaceMatch_OnStartGetPlayer(), /*
                              */ CustomRaceMatch_OnStartGetLoc(), true, true, true)
endfunction
private function On$NAME$SetupAI takes nothing returns nothing
    call PickMeleeAI(CustomRaceMatch_OnStartGetPlayer(), "$SUBNAME$.ai", null, null)
endfunction
//! endtextmacro

//! runtextmacro CRDefault_DEF_SETUP("Human", "human")
//! runtextmacro CRDefault_DEF_SETUP("Orc", "orc")
//! runtextmacro CRDefault_DEF_SETUP("NightElf", "elf")

private function OnUndeadSetup takes nothing returns nothing
    call MeleeStartingUnitsUndead(CustomRaceMatch_OnStartGetPlayer(), /*
                              */ CustomRaceMatch_OnStartGetLoc(), true, true, true)
endfunction
private function OnUndeadSetupAI takes nothing returns nothing
    call PickMeleeAI(CustomRaceMatch_OnStartGetPlayer(), "undead.ai", null, null)
    call RecycleGuardPosition(bj_ghoul[GetPlayerId(CustomRaceMatch_OnStartGetPlayer())])
endfunction

private struct S extends array
    private static method init takes nothing returns nothing
        set defaultRace[1]  = CustomRace.create(RACE_HUMAN, "Alliance")
        call defaultRace[1].defDescription("A coalition of Humans, Dwarves and Elves bound " + /*
                                        */ "together through the forging of bonds as old as " + /*
                                        */ "their kingdoms themselves.")
        call defaultRace[1].defRacePic("war3mapImported\\humanseal.blp")
        call defaultRace[1].addUnit('hpea')
        call defaultRace[1].addUnit('hfoo')
        call defaultRace[1].addUnit('hrif')
        call defaultRace[1].addUnit('hkni')

        call defaultRace[1].addUnit('hmtm')
        call defaultRace[1].addUnit('hgyr')
        call defaultRace[1].addUnit('hmpr')
        call defaultRace[1].addUnit('hsor')
        call defaultRace[1].addUnit('hspt')

        call defaultRace[1].addUnit('hgry')
        call defaultRace[1].addUnit('hmtt')

        call defaultRace[1].addHall('htow')
        call defaultRace[1].addHall('hkee')
        call defaultRace[1].addHall('hcas')

        call defaultRace[1].addStructure('htow')
        call defaultRace[1].addStructure('hkee')
        call defaultRace[1].addStructure('hcas')
        call defaultRace[1].addStructure('hhou')
        call defaultRace[1].addStructure('hbar')
        call defaultRace[1].addStructure('halt')
        call defaultRace[1].addStructure('hlum')
        call defaultRace[1].addStructure('hbla')
        call defaultRace[1].addStructure('hwtw')
        call defaultRace[1].addStructure('hvlt')
        call defaultRace[1].addStructure('harm')
        call defaultRace[1].addStructure('hars')
        call defaultRace[1].addStructure('hgra')

        call defaultRace[1].addHero('Hpal')
        call defaultRace[1].addHero('Hamg')
        call defaultRace[1].addHero('Hmkg')
        call defaultRace[1].addHero('Hblm')

        call defaultRace[1].defSetup(function OnHumanSetup)
        call defaultRace[1].defAISetup(function OnHumanSetupAI)
        call defaultRace[1].defPlaylist("Sound\\Music\\mp3Music\\HumanX1.mp3;Sound\\Music\\mp3Music\\Human3.mp3;Sound\\Music\\mp3Music\\Human2.mp3;Sound\\Music\\mp3Music\\Human1.mp3")

        set defaultRace[2]  = CustomRace.create(RACE_ORC, "Horde")
        call defaultRace[2].defDescription("Once beings with shamanic roots, these creatures " + /*
                                        */ "became as bloodthirsty as the demons. Seeking " + /*
                                        */ "refuge from their destroyed homeworld, they seek " + /*
                                        */ "even now to establish a new home in Azeroth, even " + /*
                                        */ "at the price of eternal bloodshed.")
        call defaultRace[2].defRacePic("war3mapImported\\orcseal.blp")
        call defaultRace[2].addUnit('opeo')
        call defaultRace[2].addUnit('ogru')
        call defaultRace[2].addUnit('ohun')
        call defaultRace[2].addUnit('ocat')

        call defaultRace[2].addUnit('orai')
        call defaultRace[2].addUnit('okod')
        call defaultRace[2].addUnit('oshm')
        call defaultRace[2].addUnit('odoc')

        call defaultRace[2].addUnit('otau')
        call defaultRace[2].addUnit('ospw')
        call defaultRace[2].addUnit('owvy')
        call defaultRace[2].addUnit('otbr')

        call defaultRace[2].addHall('ogre')
        call defaultRace[2].addHall('ostr')
        call defaultRace[2].addHall('ofrt')

        call defaultRace[2].addStructure('ogre')
        call defaultRace[2].addStructure('ostr')
        call defaultRace[2].addStructure('ofrt')
        call defaultRace[2].addStructure('otrb')
        call defaultRace[2].addStructure('obar')
        call defaultRace[2].addStructure('oalt')
        call defaultRace[2].addStructure('ofor')
        call defaultRace[2].addStructure('owtw')
        call defaultRace[2].addStructure('ovln')
        call defaultRace[2].addStructure('obea')
        call defaultRace[2].addStructure('osld')
        call defaultRace[2].addStructure('obea')

        call defaultRace[2].addHero('Obla')
        call defaultRace[2].addHero('Ofar')
        call defaultRace[2].addHero('Otch')
        call defaultRace[2].addHero('Oshd')

        call defaultRace[2].defSetup(function OnOrcSetup)
        call defaultRace[2].defAISetup(function OnOrcSetupAI)
        call defaultRace[2].defPlaylist("Sound\\Music\\mp3Music\\OrcX1.mp3;Sound\\Music\\mp3Music\\Orc3.mp3;Sound\\Music\\mp3Music\\Orc2.mp3;Sound\\Music\\mp3Music\\Orc1.mp3")

        set defaultRace[3]  = CustomRace.create(RACE_UNDEAD, "Scourge")
        call defaultRace[3].defDescription("Once living creatures robbed of their sweet release " + /*
                                        */ "from life, these undead beings are relentless and " + /*
                                        */ "ferocious creatures, tempered by their bond to the " + /*
                                        */ "master, the Lich King.")
        call defaultRace[3].defRacePic("war3mapImported\\undeadseal.blp")
        call defaultRace[3].addUnit('uaco')
        call defaultRace[3].addUnit('ugho')
        call defaultRace[3].addUnit('ucry')
        call defaultRace[3].addUnit('ugar')

        call defaultRace[3].addUnit('umtw')
        call defaultRace[3].addUnit('uobs')
        call defaultRace[3].addUnit('unec')
        call defaultRace[3].addUnit('uban')
        call defaultRace[3].addUnit('ushd')

        call defaultRace[3].addUnit('uabo')
        call defaultRace[3].addUnit('ufro')
        call defaultRace[3].addUnit('ubsp')

        call defaultRace[3].addHall('unpl')
        call defaultRace[3].addHall('unp1')
        call defaultRace[3].addHall('unp2')

        call defaultRace[3].addStructure('unpl')
        call defaultRace[3].addStructure('unp1')
        call defaultRace[3].addStructure('unp2')
        call defaultRace[3].addStructure('uzig')
        call defaultRace[3].addStructure('usep')
        call defaultRace[3].addStructure('uaod')
        call defaultRace[3].addStructure('ugrv')
        call defaultRace[3].addStructure('utom')
        call defaultRace[3].addStructure('ugol')
        call defaultRace[3].addStructure('uslh')
        call defaultRace[3].addStructure('utod')
        call defaultRace[3].addStructure('usap')
        call defaultRace[3].addStructure('ubon')

        call defaultRace[3].addHero('Udea')
        call defaultRace[3].addHero('Udre')
        call defaultRace[3].addHero('Ulic')
        call defaultRace[3].addHero('Ucrl')

        call defaultRace[3].defSetup(function OnUndeadSetup)
        call defaultRace[3].defAISetup(function OnUndeadSetupAI)
        call defaultRace[3].defPlaylist("Sound\\Music\\mp3Music\\UndeadX1.mp3;Sound\\Music\\mp3Music\\Undead3.mp3;Sound\\Music\\mp3Music\\Undead2.mp3;Sound\\Music\\mp3Music\\Undead1.mp3")

        set defaultRace[4]  = CustomRace.create(RACE_NIGHTELF, "Sentinels")
        call defaultRace[4].defDescription("Once prominent arcane magic practitioners, their " + /*
                                        */ "use of magic to reckless abandon had nearly torn " + /*
                                        */ "their world asunder, as the Burning Legion lay " + /*
                                        */ "waste to their world. After defeating the Burning " + /*
                                        */ "Legion, they vowed never to use arcane magic and " + /*
                                        */ "embraced druidism under the tutelage of Cenarius. " + /*
                                        */ "For centuries past, they had become a force to " + /*
                                        */ "be reckoned with.")
        call defaultRace[4].defRacePic("war3mapImported\\nightelfseal.blp")

        call defaultRace[4].addUnit('ewsp')
        call defaultRace[4].addUnit('earc')
        call defaultRace[4].addUnit('esen')
        call defaultRace[4].addUnit('ebal')

        call defaultRace[4].addUnit('edry')
        call defaultRace[4].addUnit('emtg')
        call defaultRace[4].addUnit('edoc')
        call defaultRace[4].addUnit('edot')
        call defaultRace[4].addUnit('efdr')
        call defaultRace[4].addUnit('ehip')

        call defaultRace[4].addUnit('echm')
        call defaultRace[4].addUnit('edcm')

        call defaultRace[4].addHall('etol')
        call defaultRace[4].addHall('etoa')
        call defaultRace[4].addHall('etoe')

        call defaultRace[4].addStructure('etol')
        call defaultRace[4].addStructure('etoa')
        call defaultRace[4].addStructure('etoe')
        call defaultRace[4].addStructure('emow')
        call defaultRace[4].addStructure('eaom')
        call defaultRace[4].addStructure('eate')
        call defaultRace[4].addStructure('edob')
        call defaultRace[4].addStructure('etrp')
        call defaultRace[4].addStructure('eden')
        call defaultRace[4].addStructure('eaoe')
        call defaultRace[4].addStructure('eaow')
        call defaultRace[4].addStructure('edos')

        call defaultRace[4].addHero('Ekee')
        call defaultRace[4].addHero('Emoo')
        call defaultRace[4].addHero('Edem')
        call defaultRace[4].addHero('Ewar')

        call defaultRace[4].defSetup(function OnNightElfSetup)
        call defaultRace[4].defAISetup(function OnNightElfSetupAI)
        call defaultRace[4].defPlaylist("Sound\\Music\\mp3Music\\NightElfX1.mp3;Sound\\Music\\mp3Music\\NightElf3.mp3;Sound\\Music\\mp3Music\\NightElf2.mp3;Sound\\Music\\mp3Music\\NightElf1.mp3")

        call CustomRace.addGlobalHero('Npbm')
        call CustomRace.addGlobalHero('Nbrn')
        call CustomRace.addGlobalHero('Nngs')
        call CustomRace.addGlobalHero('Nplh')
        call CustomRace.addGlobalHero('Nbst')
        call CustomRace.addGlobalHero('Nalc')
        call CustomRace.addGlobalHero('Ntin')
        call CustomRace.addGlobalHero('Nfir')
    endmethod
    implement Init
endstruct

endlibrary
