--[[
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
    |       method defAISetup(function setupfunc)
    |           - Defines an AI setup function (just in case you would like
    |             to do more than just assign AI scripts).
    |       method defSetup(function setupfunc)
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
]]

--  Start of CustomRaceCore
do
    ---@class CustomRace
    ---@field gHeroMap table - private
    ---@field gHallMap table - private
    ---@field raceFaction table - private
    ---@field raceFactionCount table - private
    ---@field globalHeroID table - private
    ---@field globalHallID table - private
    ---@field isInstance table - private
    local tb    = {
        gHeroMap        = {},
        gHallMap        = {},
        raceFaction     = {
            [1]         = {},   -- RACE_HUMAN
            [2]         = {},   -- RACE_ORC
            [3]         = {},   -- RACE_UNDEAD
            [4]         = {},   -- RACE_NIGHTELF
        },
        raceFactionCount    = {
            [1]         = 0,    -- RACE_HUMAN
            [2]         = 0,    -- RACE_ORC
            [3]         = 0,    -- RACE_UNDEAD
            [4]         = 0,    -- RACE_NIGHTELF
        },
        globalHeroID    = {},
        globalHallID    = {},
        isInstance      = {},
    }
    CustomRace      = setmetatable({}, tb)
    tb.__index      = tb
    tb.__newindex   =
    function(t, k, v)
        -- Do not allow the writing of private or readonly members.
        if (k:sub(1,1) == '_') then return end
        rawset(t, k, v)
    end

    do
        local handleID  = GetHandleId
        ---Checks whether the specified race is valid or not.
        ---@param whichRace userdata : race
        ---@return boolean
        function tb.isValidRace(whichRace)
            return handleID(whichRace) < 5
        end

        ---Returns the CustomRace faction instance at the specified index.
        ---@param whichRace userdata -> race
        ---@param index integer : 0
        ---@return CustomRaceObject | nil
        function tb.getRaceFaction(whichRace, index)
            local id    = handleID(whichRace)
            if (id >= 5) then return nil end     -- inlined isValidRace.
            if ((index < 1) or (index > tb.raceFactionCount[id])) then return nil end
            return tb.raceFaction[id][index]
        end

        ---Returns the amount of faction instances of the requested race.
        ---@param whichRace userdata -> race
        ---@return integer - Default value of 0
        function tb.getRaceFactionCount(whichRace)
            local id    = handleID(whichRace)
            return tb.raceFactionCount[id] or 0
        end

        ---Updates the number of faction instances of the requested race (based on its handle id).
        ---Since their handle id values are static, I think it's safe to use GetHandleId.
        ---@param raceID integer : The result of GetHandleId(whichRace)
        ---@param faction CustomRace
        function tb.updateFactionCount(raceID, faction)
            if (not faction) then return end
            tb.raceFactionCount[raceID] = tb.raceFactionCount[raceID] + 1
            tb.raceFaction[raceID][tb.raceFactionCount[raceID]] = faction
        end

        ---Does not do anything.
        tb.destroy  = DoNothing

        ---Creates a new faction based on the requested race.
        ---@param whichRace userdata : race
        ---@param factionName? string : Default value of (Faction [race faction count])
        ---@return CustomRaceObject | nil
        function tb.create(whichRace, factionName)
            if (not tb.isValidRace(whichRace)) then return end
            
            ---@class CustomRaceObject : CustomRace
            ---@field name string - readonly
            ---@field baseRace userdata - race, readonly
            ---@field racePic string - readonly
            ---@field hallTable table - private
            ---@field hallMap table - private  
            ---@field heroTable table - private
            ---@field heroMap table - private  
            ---@field unitTable table - private
            ---@field unitMap table - private  
            ---@field strcTable table - private
            ---@field strcMap table - private
            ---@field setupFun fun()
            local o             = {}
            o.name              = factionName or ("Faction [" .. tostring(tb.getRaceFactionCount(whichRace) + 1) .. "]")
            o.baseRace          = whichRace
            o.racePic           = ""

            o.hallTable         = {}
            o.hallMap           = {}
            o.heroTable         = {}
            o.heroMap           = {}
            o.unitTable         = {}
            o.unitMap           = {}
            o.strcTable         = {}
            o.strcMap           = {}

            tb.isInstance[o]    = true
            tb.updateFactionCount(handleID(whichRace), o)
            setmetatable(o, tb)
            return o
        end

        ---Retrieves and syncs the name, tooltip and extended tooltip of the
        ---specified object ID.
        local function instantiateStrings(objectID)
            GetObjectName(objectID)
            BlzGetAbilityExtendedTooltip(objectID, 0)
            BlzGetAbilityIcon(objectID)
        end

        ---Sanitizes the object id value from lua string to integer.
        local fourCC    = FourCC
        local table     = _G['table']
        local function sanitizeID(objectID)
            return (type(objectID) == 'string' and fourCC(objectID)) or objectID
        end

        ---Registers the specified unit id to the faction.
        ---@param unitID integer | string
        ---@param self CustomRaceObject
        function tb:addUnit(unitID)
            unitID      = sanitizeID(unitID)
            if ((not tb.isInstance[self]) or (type(unitID) ~= 'number')) then return end
            if (self.unitMap[unitID]) then return end

            instantiateStrings(unitID)
            table.insert(self.unitTable, unitID)
            self.unitMap[unitID]    = #self.unitTable
        end

        ---Registers the specified structure id to the faction.
        ---@param strcID integer | string
        ---@param self CustomRaceObject
        function tb:addStructure(strcID)
            strcID      = sanitizeID(strcID)
            if ((not tb.isInstance[self]) or (type(strcID) ~= 'number')) then return end
            if (self.strcMap[strcID]) then return end

            instantiateStrings(strcID)
            table.insert(self.strcTable, strcID)
            self.strcMap[strcID]    = #self.strcTable
        end

        ---Registers the specified hero id to the faction.
        ---Also registers the specified hero id to the global list of hero IDs.
        ---@param heroID integer | string
        ---@param self CustomRaceObject
        function tb:addHero(heroID)
            heroID      = sanitizeID(heroID)
            if ((not tb.isInstance[self]) or (type(heroID) ~= 'number')) then return end
            if (self.heroMap[heroID]) then return end

            instantiateStrings(heroID)
            table.insert(self.heroTable, heroID)
            self.heroMap[heroID]    = #self.heroTable

            if (tb.gHeroMap[heroID]) then return end
            table.insert(tb.globalHeroID, heroID)
            tb.gHeroMap[heroID]     = #tb.globalHeroID
        end

        ---Registers the specified hall id to the faction.
        ---Also registers the specified hall id to the global list of hall IDs.
        ---@param hallID integer | string
        ---@param self CustomRaceObject
        function tb:addHall(hallID)
            hallID      = sanitizeID(hallID)
            if ((not tb.isInstance[self]) or (type(hallID) ~= 'number')) then return end
            if (self.hallMap[hallID]) then return end

            instantiateStrings(hallID)
            table.insert(self.hallTable, hallID)
            self.hallMap[hallID]    = #self.hallTable

            if (tb.gHallMap[hallID]) then return end
            table.insert(tb.globalHallID, hallID)
            tb.gHallMap[hallID]     = #tb.globalHallID
        end

        ---Creates getter functions based on the given name and the desired table key.
        ---@param name string
        ---@param subname string
        ---@return fun(self) -> get$name$
        ---@return fun() -> get$name$MaxIndex
        local function makeGetters(name, subname)
            local accessName    = subname .. "Table"
            tb["get" .. name]   =
            function(self, index)
                return self[accessName][index] or 0
            end
            tb["get" .. name .. "MaxIndex"] =
            function(self)
                return #self[accessName] or 0
            end
        end

        makeGetters("Hero", "hero")
        makeGetters("Hall", "hall")
        makeGetters("Unit", "unit")
        makeGetters("Structure", "strc")

        local randint   = math.random
        ---Returns a random hero ID.
        ---@param self CustomRaceObject
        ---@return integer heroID
        function tb:getRandomHero()
            return ((#self.hallTable < 1) and 0) or self.hallMap[randint(1, #self.hallTable)]
        end

        ---Returns the maximum amount of registered hero ids.
        ---@return integer
        function tb.getGlobalHeroMaxIndex()
            return #tb.globalHeroID
        end

        ---Returns the maximum amount of registered hall ids.
        ---@return integer
        function tb.getGlobalHallMaxIndex()
            return #tb.globalHallID
        end

        ---Returns the maximum amount of registered hero ids.
        ---@param index integer
        ---@return integer
        function tb.getGlobalHero(index)
            return tb.globalHeroID[index]
        end

        ---Returns the maximum amount of registered hall ids.
        ---@param index integer
        ---@return integer
        function tb.getGlobalHall(index)
            return tb.globalHallID[index]
        end

        ---Checks if the requested hero ID is registered into the system or not.
        ---Coerces the result into a boolean.
        ---@param heroID integer | string
        ---@return boolean
        function tb.isGlobalHero(heroID)
            heroID      = sanitizeID(heroID)
            return ((type(heroID) ~= 'number') and (tb.gHeroMap[heroID] ~= nil))
        end

        ---Checks if the requested structure ID is a key structure or not.
        ---Coerces the result into a boolean.
        ---@param hallID integer | string
        ---@return boolean
        function tb.isKeyStructure(hallID)
            hallID      = sanitizeID(hallID)
            return ((type(hallID) ~= 'number') and (tb.gHallMap[hallID] ~= nil))
        end

        ---Registers the specified hero id to the global list of hero IDs.
        ---@param heroID integer | string
        function tb.addGlobalHero(heroID)
            heroID      = sanitizeID(heroID)
            if (type(heroID) ~= 'number') then return end
            if (tb.gHeroMap[heroID]) then return end

            table.insert(tb.globalHeroID, heroID)
            tb.gHeroMap[heroID]     = #tb.globalHeroID
        end

        ---Registers the specified hall id to the global list of hero IDs.
        ---@param hallID integer | string
        function tb.addGlobalHall(hallID)
            hallID      = sanitizeID(hallID)
            if (type(hallID) ~= 'number') then return end
            if (tb.gHeroMap[hallID]) then return end

            table.insert(tb.globalHallID, hallID)
            tb.gHeroMap[hallID] = #tb.globalHallID
        end
    end

    ---The setup function that will run when the timer starts ticking
    ---@param self CustomRaceObject
    ---@param setupfun fun()
    function tb:defSetup(setupfun)
        if ((not tb.isInstance[self]) or (type(setupfun) ~= 'function')) then return end
        self.setupFun       = setupfun
    end

    ---The AI setup function that will run when the timer starts ticking.
    ---You can also do some special things related to AI behavior here.
    ---@param self CustomRaceObject
    ---@param setupfun fun()
    function tb:defAISetup(setupfun)
        if ((not tb.isInstance[self]) or (type(setupfun) ~= 'function')) then return end
        self.setupAIFun     = setupfun
    end

    ---Defines the preview race image at the custom race faction selection.
    ---@param self CustomRaceObject
    ---@param imgPath? string
    function tb:defRacePic(imgPath)
        self.racePic        = imgPath or ""
    end

    ---Assigns the description of a faction.
    ---@param self CustomRaceObject
    ---@param desc? string
    function tb:defDescription(desc)
        self.desc           = desc or ""
    end

    ---Assigns the name of a faction.
    ---@param self CustomRaceObject
    ---@param name? string
    function tb:defName(name)
        self.name           = name or ""
    end
    
    ---Assigns the playlist of a faction.
    ---@param self CustomRaceObject
    ---@param plist? string
    function tb:defPlaylist(plist)
        self.playlist       = plist
    end

    do
        local try, print, call
        print   = _G[print]
        call    = xpcall

        ---Tries a function if it exists.
        ---@param fun fun()
        function try(fun)
            if (not fun) then return end
            call(fun, print)
        end

        ---Executes the setup function.
        ---@param self CustomRaceObject
        function tb:execSetup()
            try(self.setupFun, print)
        end
        ---Executes the AI setup function.
        ---@param self CustomRaceObject
        function tb:execSetupAI()
            try(self.setupAIFun, print)
        end
    end
end
--  End of CustomRaceCore