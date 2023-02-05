--[[
library CustomRacePSelection requires 
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
]]

do
    local w3type    = Wc3Type
    local getPID    = GetPlayerId
    if (not Wc3Type) then
        -------------------
        ----| Wc3Type |----
        -------------------

        ---Returns the type of a warcraft object as string, e.g. "location", when inputting a location.
        ---@param input any
        ---@return string
        function Wc3Type(input)
            local typeString = type(input)
            if typeString == 'number' then
                return (math.type(input) =='float' and 'real') or 'integer'
            elseif typeString == 'userdata' then
                typeString = tostring(input) --toString returns the warcraft type plus a colon and some hashstuff.
                return string.sub(typeString, 1, (string.find(typeString, ":", nil, true) or 0) -1) --string.find returns nil, if the argument is not found, which would break string.sub. So we need or as coalesce.
            else
                return typeString
            end
        end
        w3type      = Wc3Type
    end

    local COMP_CUSTOM_FACTION   = true

    ---@class CustomRacePSelection
    ---@readonly isSinglePlayer         -- boolean
    ---@readonly choicedPlayerSize      -- integer
    ---@readonly unchoicedPlayerSize    -- integer
    ---@private _playerTables -> contains list of CustomRacePSelectionObject instances.
    ---@private _userPlayerCount
    ---@private _baseTechID
    ---@private _choiced
    ---@private _unchoiced
    local crpSelection
    crpSelection                = {
        _playerTables           = {},
        _baseTechID             = {},
        _choiced                = {},
        _unchoiced              = {},
        _userPlayerCount        = 0,
        isSinglePlayer          = false,
    }

    _G["CustomRacePSelection"]  = setmetatable({}, crpSelection)
    _G["CRPSelection"]          = setmetatable({}, {
        __index                 = function(_, k)
            if w3type(k) ~= 'player' then
                return nil
            end
            return CustomRacePSelection[getPID(k)]
        end
    })

    do
        ---@class CustomRacePSelectionObject : CustomRacePSelection
        ---@field id integer
        local crpSelectObj      = {}
        crpSelectObj.__index    =
        function(t, k)
            if type(crpSelectObj[k]) ~= 'table' then
                return crpSelectObj[k]
            end
            return crpSelectObj[k].get(t)
        end
        crpSelectObj.__newindex =
        function(t, k, v)
            if (crpSelectObj[k] == nil) then
                rawset(t, k, v)
                return t
            end
            if (type(crpSelectObj[k]) ~= 'table') then
                return t
            end
            crpSelectObj[k].set(t, v)
            return t
        end

        crpSelection.__index    =
        function(t, k)
            if type(k) == 'number' then
                k   = k + 1
                if (not crpSelection._playerTables[k]) then
                    ---@type CustomRacePSelectionObject
                    local o     = {
                        id                  = k,
                        faction             = 0,

                        raceIndex           = 0,

                        baseChoice          = 0,
                        focusFaction        = 0,
                        focusFactionStack   = 0,

                        techtree            = 0,
                        focusTechtree       = 0,
                        focusTechtreeStack  = 0,
                        focusTechID         = 0,
                    }
                    setmetatable(o, crpSelectObj)
                    crpSelection._playerTables[k] = o
                end
                return crpSelection._playerTables[k]
            end
            return crpSelection[k]
        end

        local getChunkCount = "CustomRaceUI_GetTechtreeChunkCount"

        ---Get the base tech ID for a specific techtree chunk for a given player (by index).
        ---The method is invoked in this manner: CustomRacePSelection[playerID]:getBaseTechId(index)
        ---@param index integer
        ---@return integer
        function crpSelectObj:getBaseTechID(index)
            return crpSelection._baseTechID[(self.id - 1)*getChunkCount() + index]
        end

        ---Set the base tech ID for a specific techtree chunk for a given player (by index) to the
        ---specified value. The method is invoked in this manner:
        ---CustomRacePSelection[playerID]:getBaseTechId(index)
        ---@param index integer
        ---@param value integer
        function crpSelectObj:setBaseTechID(index, value)
            crpSelection._baseTechID[(self.id - 1)*getChunkCount() + index] = value
        end

        ---Generates three functions, an insert function and a remove function.
        ---@param tablename string
        local function choiceFactory(tablename, sizeAccessName)
            local addFun, subFun, cmpFun

            crpSelection[sizeAccessName]    = 0
            ---This function adds a player handle to the specified table list if the player isn't
            ---already present and returns true. If the player is already in the table list, this
            ---returns false.
            ---@param p userdata -> player
            ---@return boolean
            function addFun(p)
                local i = 1
                while (i <= #crpSelection[tablename]) do
                    if crpSelection[tablename][i] == p then
                        return false
                    end
                    i   = i + 1
                end
                crpSelection[tablename][i]    = p
                crpSelection[sizeAccessName]  = #crpSelection[tablename]
                return true
            end

            ---This function removes a player handle from the specified table list if found, returning
            ---true if removal is successful. Returns false otherwise.
            ---@param p userdata -> player
            ---@return boolean
            function subFun(p)
                local i = #crpSelection[tablename]
                while (i > 0) do
                    if crpSelection[tablename][i] == p then
                        break
                    end
                    i   = i - 1
                end
                if (i <= 0) then
                    return false
                end
                while (i < #crpSelection[tablename]) do
                    crpSelection[tablename][i]    = crpSelection[tablename][i + 1]
                    i   = i + 1
                end
                crpSelection[tablename][i]    = nil
                crpSelection[sizeAccessName]  = #crpSelection[tablename]
                return true
            end

            ---This function checks if the player handle is found within the specified table list.
            ---@param p userdata -> player
            ---@return boolean
            function cmpFun(p)
                local i = #crpSelection[tablename]
                while (i > 0) do
                    if crpSelection[tablename][i] == p then
                        return true
                    end
                    i   = i - 1
                end
                return false
            end
            return addFun, subFun, cmpFun
        end

        crpSelection.addChoicedPlayer,
        crpSelection.removeChoicedPlayer,
        crpSelection.hasChoicedPlayer = choiceFactory("_choiced", "choicedPlayerSize")

        crpSelection.addUnchoicedPlayer,
        crpSelection.removeUnchoicedPlayer,
        crpSelection.hasUnchoicedPlayer = choiceFactory("_unchoiced", "unchoicedPlayerSize")
    end

    --- An external initialization function to be called elsewhere
    function crpSelection.init()
        local i     = 0
        ---@type userdata player
        local p     = nil
        ---@type userdata rect
        local r     = nil
        while (i < bj_MAX_PLAYER_SLOTS - 4) do
            p                                   = Player(i)
            r                                   = GetPlayerRace(p)
            CustomRacePSelection[i].raceIndex   = GetHandleId(r)

            --  For string synchronization purposes.
            GetPlayerName(p)
            if (GetPlayerController(p) == MAP_CONTROL_USER) and 
               (GetPlayerSlotState(p)  == PLAYER_SLOT_STATE_PLAYING) then
                crpSelection.userPlayerCount     = crpSelection.userPlayerCount + 1
                if (CustomRace.getRaceFactionCount(r) > 1) then
                    thistype.addChoicedPlayer(p)
                else
                    CustomRacePSelection[i].faction = 1
                    thistype.addUnchoicedPlayer(p)
                end

            elseif (GetPlayerSlotState(p) == PLAYER_SLOT_STATE_PLAYING) then
                if COMP_CUSTOM_FACTION then
                    thistype[i].faction = GetRandomInt(1, CustomRace.getRaceFactionCount(r))
                else
                    thistype[i].faction = 1
                end
                thistype.addUnchoicedPlayer(p)
            end
            i       = i + 1
        end
        crpSelection.isSinglePlayer  = (crpSelection.userPlayerCount == 1)
    end
end