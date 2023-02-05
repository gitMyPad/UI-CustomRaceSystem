--[[
----------------------
*/  CustomRaceCore, /*
----------------------

----------------------
*/  Init,           /*
----------------------

------------------------------
*/  optional FrameLoader    /*
------------------------------

    ---------------------------------------------------------------------------
|
|   CustomRaceUI
|
|---------------------------------------------------------------------------
|
|   - function MainFrameInitiallyVisible() -> boolean
|       - determines whether the main frame is visible at the start
|         of the game. Must not be touched!
|
|---------------------------------------------------------------------------
|
|   Configuration Section:
|
|---------------------------------------------------------------------------
|
|   GetMainFrameCenterX() -> real
|   GetMainFrameCenterY() -> real
|       - Determines the position of the center of the main frame.
|
|   GetTechtreeTooltipOffsetX() -> real
|   GetTechtreeTooltipOffsetY() -> real
|       - Determines the position of the leftmost lower edge of the
|         tooltip frame.
|
|   GetTechtreeChunkCount() -> integer
|       - Determines the number of techtree chunks to generate.
|       - An example of a techtree chunk may consist of units
|         existing as part of the techtree of a certain faction.
|
|   GetTechtreeIconRowMax() -> integer
|       - Returns the maximum amount of icons per column
|         within a given chunk.
|       - o
|         o --> 2
|   GetTechtreeIconColumnMax() -> integer
|       - Returns the maximum amount of icons per row
|         within a given chunk.
|
|       - o o o o --> 4
|
|   InitChunkNames()
|       - While not considered a traditionally configurable
|         function, this function provides one with the
|         means to edit the labels of each techtree chunk,
|         albeit indirectly.
|
|   GetMaxDisplayChoices() -> integer
|       - The amount of choices for factions that are displayed at any given time.
|       - NOTE: The actual maximum number of factions is practically unlimited
|         and should not be confused with the value here.
|   GetChoiceSizeOffset() -> real
|       - The difference between the total height of the choices and the height
|         of their container frame.
|
|   GetBarModel() -> string
|       - The model art for the "bar" frame (which is actually a backdrop frame)
|         (behind the scenes.)
|   GetBarTransparency() -> real
|       - The transparency of the "bar" frame. Accepts values from 0.0 to 1.0.
|       - A transparency of 1 will render the frame invisible. A transparency
|         of 0 will render the frame completely opaque.
|
|---------------------------------------------------------------------------
|
|   CustomRaceInterface method guide:
|
|---------------------------------------------------------------------------
|
|   Although not really meant for public usage, the public methods
|   "available" to the user are written to make certain interactions
|   with some of the elements in the main frame as direct and easy
|   as possible. In that regard, expect performance to be sacrificed
|   a bit.
|
|   If opting for speed, one can directly access most of the elements
|   and make changes from there. Performance may improve, but the
|   maintainability of the code might be negatively affected.
|
|   All of the following methods are static:
|
|---------------------------------------------------------------------------
|
|   Getters:
|       method getTechtreeIcon(int techChunk, int row, int col) -> framehandle
|           - returns the techtree icon at the specified location
|             and chunk.
|
|       method getTechtreeIconRaw(int index) -> framehandle
|           - returns the techtree icon at the specified index.
|             Be wary, as this is not protected from out of bounds
|             results.
|
|       method getChoiceButton(int index) -> framehandle
|           - returns one of the choice buttons (found within the
|             choice container frame at the lower left portion.)
|
|       method getTechtreeArrow(int techChunk, bool isUp) -> framehandle
|           - returns one of the two techtree arrows associated
|             with the requested chunk.
|
|       method getTechtreeArrowID(framehandle arrow) -> int
|           - returns the index of the arrow handle.
|
|       method getChoiceArrow(bool isUp) -> framehandle
|           - returns one of the two choice arrows bound to the
|             slider frame.
|
|       method getChoiceArrowID(framehandle arrow) -> int
|           - returns the index of the arrow handle.
|
|       method getSliderValue() -> int
|           - self-explanatory
|
|       method getChunkFromIndex(int id) -> int
|           - Retrieves the chunk containing the techtree
|             icon id.
|
|   Setters:
|       method setTooltipName(string name)
|           - sets the text entry for the name portion of the
|             tooltip frame to the specified parameter. Empty
|             string defaults into "Unit Name Missing!"
|
|       method setTooltipDesc(string name)
|           - similar to setTooltipName, this sets the entry
|             of the description portion of the tooltip frame
|             to the specified parameter. Defaults into "Tooltip
|             Missing!"
|
|       method setDescription(string desc)
|           - Assigns the contents to the textarea frame. Used
|             for giving a faction some background info or
|             description, etc.
|
|       method setChoiceName(int index, string name)
|           - Sets the name of the selected choice button to
|             the specified name. Defaults to "Factionless"
|
|       method setTechtreeIconDisplay(int techChunk, int row, int col, string display)
|           - Sets the background of the specified techtree
|             icon to the model pointed by the display path.
|
|       method setTechtreeIconDisplayEx(framehandle icon, string display)
|           - A more direct version of the above function.
|             Useful when the user is already using the
|             appropriate icon directly.
|
|       method setTechtreeIconDisplayByID(int contextID, string display)
|           - An index-based version of the above function.
|
|       method setBarProgress(real value)
|           - Sets the width of the visual bar to a specified
|             ratio relative to its parent frame that is equal
|             to the specified value.
|
|       method setMainAlpha(real ratio)
|           - Modifies the alpha coloring of the main frame.
|
|       method setFactionDisplay(string iconPath)
|           - Updates the screen texture at the top left section
|             of the main frame. Automatically handles visibility.
|           - Setting the display to an empty string hides it
|             while setting the display to any other value shows
|             it.
|
|       method setFactionName(string name)
|           - Sets the contents of the text frame above the screen
|             texture to the specified name. Defaults to "Faction
|             Name".
|           - It is to be used in conjunction with the selection
|             of the current frame.
|
|       method setMainPos(x, y)
|           - Moves the center of the main frame to that specified
|             position.
|
|       method setSliderValue(real value)
|           - Changes the position value of the slider button.
|
|       method setSliderMaxValue(int max)
|           - Sets the slider's maximum value to the specified
|             amount. Cannot go lower than 1.
|           - Has the added effect of automatically updating
|             the slider value.
|
|   Visibility:
|       method isMainVisible() -> bool
|       method isTooltipVisible() -> bool
|       method isSliderVisible() -> bool
|       method isChoiceButtonVisible(int index) -> bool
|       method isTechtreeChunkVisible(int techChunk) -> bool
|       method isChoiceArrowVisible(int isUp) -> bool
|       method isTechtreeArrowVisible(int techChunk, bool isUp) -> bool
|       method isFactionNameVisible() -> bool
|       method isTechtreeIconVisible(int contextId) -> bool
|           - Returns the visibility state of the following frames in order:
|               - Main frame
|               - Tooltip
|               - Slider adjacent to container frame
|               - Choice button
|               - Techtree chunk contained inside techtree container frame
|               - Arrow buttons adjacent to the techtree chunk frames.
|               - Techtree arrows adjacent to the slider.
|               - Faction Name
|               - Techtree icon
|
|       method setMainVisible(bool flag)
|       method setTooltipVisible(bool flag)
|       method setSliderVisible(bool flag)
|       method setChoiceButtonVisible(int index, bool flag)
|       method setTechtreeChunkVisible(int techChunk, bool flag)
|       method setChoiceArrowVisible(int isUp, bool flag)
|       method setTechtreeArrowVisible(int techChunk, bool isUp, bool flag)
|       method setFactionNameVisible(bool flag)
|       method setTechtreeIconVisible(int contextId, bool flag)
|           - Modifies the visibility state of the following frames in order:
|               - Main frame
|               - Tooltip
|               - Slider adjacent to container frame
|               - Choice button
|               - Techtree chunk contained inside techtree container frame
|               - Arrow buttons adjacent to the techtree chunk frames.
|               - Techtree arrows adjacent to the slider.
|               - Faction Name
|               - Techtree icon
|
|---------------------------------------------------------------------------
|
|   Aside from the methods publicly available, the following members are
|   readonly for the user's convenience (should they choose to update it):
|
|   CustomRaceInterface = {
|       framehandle main
|       framehandle iconFrame
|       framehandle descArea
|       framehandle factFrame
|       framehandle confirmFrame
|       framehandle choiceFrame
|       framehandle techFrame
|       framehandle slider
|       framehandle bar
|       framehandle barParent
|       framehandle techTooltip
|       framehandle techTooltipName
|       framehandle techTooltipDesc
|       framehandle techtreeIcons = {},
|       framehandle techtreeChunk = {},
|       framehandle techtreeArrow = {},
|       framehandle choiceArrow = {},
|       framehandle choiceButton = {},
|   }
|
    ---------------------------------------------------------------------------
]]

do
    local IN_DEBUG_MODE  = true
    local DebugFrameModel

    if IN_DEBUG_MODE then
        ---The path to a picture to be displayed for prior debugging.
        ---Now an artifact of the past. Do not use.
        ---@return string
        DebugFrameModel =
        function() 
            return "ReplaceableTextures\\CommandButtons\\BTNGhoul.tga"
        end
    end

    ---The path of the imported TOC file. Defaults to war3mapImported\\CustomRaceTOC.toc
    ---Can be adjusted by the user.
    ---@return string
    local function GetTOCPath() 
        return "war3mapImported\\CustomRaceTOC.toc"
    end

    ---Up Arrow texture path
    ---@return string
    local function GetUpArrowButtonModel() 
        return "UI\\Widgets\\Glues\\SinglePlayerSkirmish-ScrollBarUpButton.blp"
    end

    ---Down Arrow texture path
    ---@return string
    local function GetDownArrowButtonModel() 
        return "UI\\Widgets\\Glues\\SinglePlayerSkirmish-ScrollBarDownButton.blp"
    end

    ---Debug parameter function used to show or hide the main frame while developing the resource.
    ---Should always be false in practical usage.
    ---@return boolean
    local function MainFrameInitiallyVisible() 
        return false
    end

    ---The width of a techtree container / chunk.
    ---A techtree chunk contains a list of relevant units within a techtree.
    ---@return number
    local function GetTechtreeChunkTextFrameWidth() 
        return 0.024
    end

    ---The height of a techtree container / chunk.
    ---@return number
    local function GetTechtreeChunkTextFrameHeight() 
        return 0.018
    end

    ---I forgot exactly what this parameter pertains to. Probably the width padding.
    ---@return number
    local function GetTechtreeChunkHolderWidthOffset() 
        return 0.004
    end

    ---Probably the height padding.
    ---@return number
    local function GetTechtreeChunkHolderHeightOffset() 
        return 0.004
    end

    ---Defines the width of each techtree icon. Also serves as the height of each
    ---techtree icon.
    ---@return number
    local function GetTechtreeArrowMaxWidth() 
        return 0.032
    end

    --  ====================================================    //
    --                  CONFIGURATION SECTION                   //
    --  ====================================================    //
    --- Ripped this part from Bribe's vJass to Lua converter.
    local techName                  = __jarray("")
    local SCOPE_PREFIX              = "CustomRaceUI_"
    _G[SCOPE_PREFIX .. "techName"]  = techName

    local TECHTREE_CHUNK_UNIT       = 1
    local TECHTREE_CHUNK_BUILDING   = 2
    local TECHTREE_CHUNK_HEROES     = 3
    local TECHTREE_CHUNK_UPGRADES   = 4

    ---A publicly visible function parameter. Describes the center x value of the main frame.
    ---@return number
    local function GetMainFrameCenterX()
        return 0.342
    end
    _G[SCOPE_PREFIX .. "GetMainFrameCenterX"] = GetMainFrameCenterX

    ---A publicly visible function parameter. Describes the center Y value of the main frame.
    ---@return number
    local function GetMainFrameCenterY()
        return 0.338
    end
    _G[SCOPE_PREFIX .. "GetMainFrameCenterY"] = GetMainFrameCenterY

    ---Tooltip x-offset from the right framepoint of the main frame.
    ---@return number
    local function GetTechtreeTooltipOffsetX()
        return 0.016
    end

    ---Tooltip y-offset from the right framepoint of the main frame.
    ---Upon revisiting this, I realized that I hard-coded the framepoint where
    ---the tooltip will be positioned.
    ---@return number
    local function GetTechtreeTooltipOffsetY()
        return -0.06
    end

    ---A publicly visible function.
    ---The maximum number of choices that can be shown at any given point in time.
    ---@return integer
    local function GetMaxDisplayChoices()
        return 3
    end
    _G[SCOPE_PREFIX .. "GetMaxDisplayChoices"] = GetMaxDisplayChoices

    ---The Y-offset for each faction choice. Making an X-offset for the same wouldn't
    ---look good now, would it?
    ---@return number
    local function GetChoiceSizeOffset()
        return 0.003
    end

    ---The number of techtree chunks that the custom frame will display.
    ---@return integer
    local function GetTechtreeChunkCount()
        return 2
    end
    _G[SCOPE_PREFIX .. "GetTechtreeChunkCount"] = GetTechtreeChunkCount

    ---Maximum amount of displayed techtree icons to be contained in a row.
    ---@return integer
    local function GetTechtreeIconColumnMax()
        return 4
    end
    _G[SCOPE_PREFIX .. "GetTechtreeIconColumnMax"] = GetTechtreeIconColumnMax

    ---The maximum amount of rows for each techtree chunk.
    ---@return integer
    local function GetTechtreeIconRowMax()
        return 2
    end
    _G[SCOPE_PREFIX .. "GetTechtreeIconRowMax"] = GetTechtreeIconRowMax

    ---This is for the progress bar displayed at the bottom of the main frame.
    ---Should reveal the amount of time left for remaining players to choose.
    ---Does not apply in singleplayer or one-player LAN.
    ---@return string
    local function GetBarModel()
        return "ReplaceableTextures\\Teamcolor\\Teamcolor01.tga"
    end
    local function GetBarTransparency()
        return 0.55
    end
    local function InitChunkNames()
        techName[TECHTREE_CHUNK_UNIT]       = "Units:"
        techName[TECHTREE_CHUNK_BUILDING]   = "Buildings:"
        techName[TECHTREE_CHUNK_HEROES]     = "Heroes:"
        techName[TECHTREE_CHUNK_UPGRADES]   = "Upgrades:"
    end

    -- ====================================================    //
    --               END CONFIGURATION SECTION                 //
    -- ====================================================    //

    local GetFrameIndex
    do
        local tb        = {map={}}
        GetFrameIndex   =
        ---@param whichButton userdata -> framehandle
        ---@return integer
        function(whichButton)
            if (not tb.map[whichButton]) then
                tb[#tb + 1]         = whichButton
                tb.map[whichButton] = #tb
            end
            return tb.map[whichButton]
        end
    end

    local Debugger  
    if IN_DEBUG_MODE then
        do
            Debugger        = {
                warningRaised   = 0,
                warning         = __jarray(""),
            }

            function Debugger.prepWarning(source, msg)
                Debugger.warningRaised   = Debugger.warningRaised + 1
                Debugger.warning[Debugger.warningRaised]  = "\n    (" .. tostring(Debugger.warningRaised) ..
                                            ") In " .. source .. ": (" .. msg .. ")."  
            end

            function Debugger.raiseWarning(source)
                local msg       = source .. ": Warning Raised!"
                local i         =  1
                if Debugger.warningRaised < 1 then return end
                repeat
                    msg = msg .. (Debugger.warning[i] or "")
                    i   = i + 1
                until (i > Debugger.warningRaised)
                Debugger.warningRaised   = 0
                DisplayTimedTextToPlayer(GetLocalPlayer(), 0.0, 0.0, 60.0, msg)
            end
        end
    end

    do
        ---@class CustomRaceInterface
        ---@field techtreeIcons table userdata -> framehandle
        ---@field techtreeChunk table userdata -> framehandle
        ---@field techtreeArrow table userdata -> framehandle
        ---@field choiceButton table userdata -> framehandle
        ---@field choiceArrow table userdata -> framehandle
        ---@field choiceButtonId table userdata -> framehandle
        ---@field techtreeIconContextId table userdata -> framehandle
        ---@field main userdata userdata -> framehandle
        ---@field iconFrame userdata userdata -> framehandle
        ---@field descArea userdata userdata -> framehandle
        ---@field factFrame userdata userdata -> framehandle
        ---@field confirmFrame userdata userdata -> framehandle
        ---@field choiceFrame userdata userdata -> framehandle
        ---@field techFrame userdata userdata -> framehandle
        ---@field slider userdata userdata -> framehandle
        ---@field bar userdata userdata -> framehandle
        ---@field barParent userdata userdata -> framehandle
        ---@field techTooltip userdata userdata -> framehandle
        ---@field techTooltipName userdata userdata -> framehandle
        ---@field techTooltipDesc userdata userdata -> framehandle
        ---@field iconsPerChunk integer
        ---@field sliderMinValue integer
        ---@field sliderMaxValue integer
        ---@field iconTexture string
        local crInterface           = {
            techtreeIcons           = {},
            techtreeChunk           = {},
            techtreeArrow           = {},
            choiceButton            = {},
            choiceArrow             = {},
            choiceButtonId          = __jarray(0),
            techtreeIconContextId   = __jarray(0),
            iconsPerChunk           = 0,
            sliderMinValue          = 0,
            sliderMaxValue          = 1,
            iconTexture             = "",
        }
        _G["CustomRaceInterface"]   = setmetatable({}, crInterface)

        ---Returns a bounded value for the parameter "a" between max and min
        ---@param a number
        ---@param max number
        ---@param min number
        ---@return number
        function crInterface.getBoundedRealValue(a, min, max)
            max, min    = ((max < min) and min) or max, ((max < min) and max) or min
            a           = ((max < a) and max) or ((a < min) and min) or a
            return a
        end

        ---Returns a bounded integer value for the parameter "a" between max and min.
        ---Cloning of function done to play well with EmmyAnnotation.
        ---@param a number
        ---@param min number
        ---@param max number
        ---@return number
        function crInterface.getBoundedIntValue(a, min, max)
            a = crInterface.getBoundedRealValue(a, min, max)
            return a
        end

        ---Retrieves the chunk info index based on the techChunk, row and column
        ---@param techChunk integer
        ---@param row integer
        ---@param col integer
        ---@return integer
        function crInterface.chunkInfo2Index(techChunk, row, col)
            techChunk   = crInterface.getBoundedIntValue(techChunk, 1, GetTechtreeChunkCount())
            row         = crInterface.getBoundedIntValue(row, 1, GetTechtreeIconRowMax())
            col         = crInterface.getBoundedIntValue(col, 1, GetTechtreeIconColumnMax())
            return (techChunk-1)*GetTechtreeIconRowMax()*GetTechtreeIconColumnMax() +
                (row-1)*GetTechtreeIconColumnMax() + col
        end

        --  =============================================================   --
        --                      External Struct API                         --
        --  =============================================================   --

        --  ==================  --
        --      Getter API      --
        --  ==================  --

        ---Returns the icon framehandle based on the techChunk, row and column.
        ---@param techChunk integer
        ---@param row integer
        ---@param col integer
        ---@return userdata framehandle
        function crInterface.getTechtreeIcon(techChunk, row, col)
            return crInterface.techtreeIcons[crInterface.chunkInfo2Index(techChunk, row, col)]
        end

        ---Returns the icon framehandle based on the index value itself.
        ---@param index integer
        ---@return userdata framehandle
        function crInterface.getTechtreeIconRaw(index)
            return crInterface.techtreeIcons[index]
        end

        ---Returns the icon choice button based on the index value.
        ---@param index integer
        ---@return userdata framehandle
        function crInterface.getChoiceButton(index)
            return crInterface.choiceButton[index]
        end

        ---Returns either the up button or the down button of the tech chunk.
        ---@param techChunk integer
        ---@param isUp boolean
        ---@return userdata framehandle
        function crInterface.getTechtreeArrow(techChunk, isUp)
            techChunk   = crInterface.getBoundedIntValue(techChunk, 1, GetMaxDisplayChoices())
            local incr  = ((isUp and 1) or 2)
            return crInterface.techtreeArrow[2*(techChunk - 1) + incr]
        end

        ---Iterates through all techtree arrow ids to retrieve the index of the arrow framehandle.
        ---@param arrow userdata framehandle
        ---@return integer
        function crInterface.getTechtreeArrowID(arrow)
            local i, j = 1, GetTechtreeChunkCount()*2
            while (i <= j) do
                if crInterface.techtreeArrow[i] == arrow then return i end
                i = i + 1
            end
            return 0
        end

        ---Returns either the up choice arrow or the down choice arrow.
        ---@param isUp boolean
        ---@return userdata - framehandle
        function crInterface.getChoiceArrow(isUp)
            return ((isUp) and crInterface.choiceArrow[1]) or crInterface.choiceArrow[2]
        end

        ---Returns the id of either the up choice arrow or the down choice arrow.
        ---A result of 0 indicates that the provided framehandle is not an up choice arrow
        ---or down choice arrow.
        ---@param arrow userdata framehandle
        ---@return integer
        function crInterface.getChoiceArrowID(arrow)
            if arrow == crInterface.choiceArrow[1] then
                return 1
            elseif arrow == crInterface.choiceArrow[2] then
                return 2
            end
            return 0
        end

        ---Returns the index of the faction choice framehandle.
        ---Values range from 1 - 3, based on the user's input.
        ---@param choice userdata -> framehandle
        ---@return integer
        function crInterface.getChoiceButtonID(choice)
            return crInterface.choiceButtonId[GetFrameIndex(choice)]
        end

        ---Returns the ID of the requested techtree icon.
        ---@param icon userdata -> framehandle
        ---@return integer
        function crInterface.getTechtreeIconID(icon)
            return crInterface.techtreeIconContextId[GetFrameIndex(icon)]
        end

        ---Returns the current value of the slider frame.
        ---@return integer
        function crInterface.getSliderValue()
            return R2I(BlzFrameGetValue(crInterface.slider) + 0.01)
        end

        ---Returns the parent chunk by the ID of the techtree icon.
        ---For example, with the following parameters (#col = 4, #row = 2),
        ---Techtree icons with IDs ranging from 1 to 8 (4*2) are contained in chunk 1.
        ---Likewise, IDs ranging from 9 to 16 are contained in chunk 2.
        ---@param id integer
        ---@return integer
        function crInterface.getChunkFromIndex(id)
            return ((id - 1) / crInterface.iconsPerChunk) + 1
        end

        --  ==================  --
        --      Setter API      --
        --  ==================  --

        ---Sets the text value of the name of the tooltip to the specified value.
        ---@param name string
        function crInterface.setTooltipName(name)
            if name == "" then
                name    = "Unit Name Missing!"
            end
            BlzFrameSetText(crInterface.techTooltipName, name)
        end

        ---Sets the text value of the body of the tooltip to the specified value.
        ---@param desc string
        function crInterface.setTooltipDesc(desc)
            if desc == "" then
                desc    = "Tooltip Missing!"
            end
            BlzFrameSetText(crInterface.techTooltipDesc, desc)
        end

        ---Sets the text value of the faction descriptor to the specified value.
        ---@param content string
        function crInterface.setDescription(content)
            BlzFrameSetText(crInterface.descArea, content)
        end

        ---Sets the text value of the desired choice framehandle to the supplied name.
        ---@param index integer
        ---@param name string
        function crInterface.setChoiceName(index, name)
            index   = crInterface.getBoundedIntValue(index, 1, GetMaxDisplayChoices())
            if name == "" then
                name    = "Factionless"
            end
            BlzFrameSetText(crInterface.choiceButton[index], name)
        end

        ---Sets the texture of a specified Techtree Icon (by position) to the image specified by the "display" file path.
        ---@param techChunk integer
        ---@param row integer
        ---@param col integer
        ---@param display string
        function crInterface.setTechtreeIconDisplay(techChunk, row, col, display)
            local index     = crInterface.chunkInfo2Index(techChunk, row, col)
            local icon      = BlzGetFrameByName("CustomRaceFactionTechtreeIconActiveBackdrop", index)
            local pIcon     = BlzGetFrameByName("CustomRaceFactionTechtreeIconBackdrop", index)
            BlzFrameSetTexture(icon, display, 0, true)
            BlzFrameSetTexture(pIcon, display, 0, true)
        end

        ---Sets the texture of a specified Techtree Icon to the image specified by the "display" file path.
        ---@param techIcon userdata framehandle
        ---@param display string
        function crInterface.setTechtreeIconDisplayEx(techIcon, display)
            local index     = crInterface.techtreeIconContextId[GetFrameIndex(techIcon)]
            if index == 0 then
                return
            end
            local icon      = BlzGetFrameByName("CustomRaceFactionTechtreeIconActiveBackdrop", index)
            local pIcon     = BlzGetFrameByName("CustomRaceFactionTechtreeIconBackdrop", index)
            BlzFrameSetTexture(icon, display, 0, true)
            BlzFrameSetTexture(pIcon, display, 0, true)
        end

        ---Sets the texture of a specified Techtree Icon (by index) to the image specified by the "display" file path.
        ---@param contextID integer
        ---@param display string
        function crInterface.setTechtreeIconDisplayByID(contextID, display)
            local icon  = BlzGetFrameByName("CustomRaceFactionTechtreeIconActiveBackdrop", contextID)
            local pIcon = BlzGetFrameByName("CustomRaceFactionTechtreeIconBackdrop", contextID)
            BlzFrameSetTexture(icon, display, 0, true)
            BlzFrameSetTexture(pIcon, display, 0, true)
        end

        ---Sets the progress value of the bar to the specified amount
        ---Values range from 0.0 - 1.0 with 1.0 filling up the entire bar
        ---and 0.0 being completely empty.
        ---@param amount number
        function crInterface.setBarProgress(amount)
            amount  = crInterface.getBoundedRealValue(amount, 0.0, 1.0)
            BlzFrameSetSize(crInterface.bar,
                            BlzFrameGetWidth(crInterface.barParent)*(amount),
                            BlzFrameGetHeight(crInterface.barParent))
        end

        ---Values range from 0.0 - 1.0 with 1.0 being completely visible
        ---and 0.0 being completely invisible
        ---@param ratio number
        function crInterface.setMainAlpha(ratio)
            ratio   = crInterface.getBoundedRealValue(ratio, 1.0, 0.0)
            BlzFrameSetAlpha(crInterface.main, R2I(255.0*ratio))
            -- I must've done this to ensure that iconFrame gets hidden,
            -- but I might've failed to consider the opposite case.
            if crInterface.iconTexture == "" and BlzFrameIsVisible(crInterface.iconFrame) then
                BlzFrameSetVisible(crInterface.iconFrame, false)
            end
            BlzFrameSetAlpha(crInterface.bar, R2I(255.0*ratio*(1.0 - GetBarTransparency())))
        end

        ---Displays the representative faction image to the top-left
        ---of the main frame. Specifying an empty string automatically
        ---hides the frame.
        ---@param imagePath string
        function crInterface.setFactionDisplay(imagePath)
            crInterface.iconTexture = imagePath
            if imagePath == "" and BlzFrameIsVisible(crInterface.iconFrame) then
                BlzFrameSetVisible(crInterface.iconFrame, false)
            elseif (imagePath ~= "") and (not BlzFrameIsVisible(crInterface.iconFrame)) then
                BlzFrameSetVisible(crInterface.iconFrame, true)
            end
            BlzFrameSetTexture(crInterface.iconFrame, imagePath, 0, true)
        end

        ---Sets the text value of the Faction Name handle to the specified value.
        ---When an empty string is supplied, "Faction Name" is displayed instead.
        ---@param name string
        function crInterface.setFactionName(name)
            if name == "" then
                name    = "Faction Name"
            end
            BlzFrameSetText(crInterface.factFrame, name)
        end

        ---Sets the position of the main frame based on its center point.
        ---@param x number
        ---@param y number
        function crInterface.setMainPos(x, y)
            BlzFrameSetAbsPoint(crInterface.main, FRAMEPOINT_CENTER, x, y)
        end

        ---Sets the value of the slider to the specified value.
        ---@param value integer
        function crInterface.setSliderValue(value)
            BlzFrameSetValue(crInterface.slider, value)
        end

        ---Sets the maximum value of the slider to the specified value.
        ---Also has the effect of adjusting the current value of the slider.
        ---@param value integer
        function crInterface.setSliderMaxValue(value)
            local preValue              = BlzFrameGetValue(crInterface.slider)
            local preMax                = crInterface.sliderMaxValue
            value                       = IMaxBJ(value, 1)
            crInterface.sliderMaxValue  = value
            BlzFrameSetMinMaxValue(crInterface.slider, 0.0, value)
            BlzFrameSetValue(crInterface.slider, preValue + value - preMax)
        end

        --  ==============================  --
        --      Boolean State Check API     --
        --  ==============================  --

        ---@return boolean
        function crInterface.isMainVisible()
            return BlzFrameIsVisible(crInterface.main)
        end

        ---@return boolean
        function crInterface.isTooltipVisible()
            return BlzFrameIsVisible(crInterface.techTooltip)
        end

        ---@return boolean
        function crInterface.isSliderVisible()
            return BlzFrameIsVisible(crInterface.slider)
        end

        ---Check if the choice button frame (by index) is visible or not.
        ---@param index integer
        ---@return boolean
        function crInterface.isChoiceButtonVisible(index)
            index       = crInterface.getBoundedIntValue(index, 1, GetMaxDisplayChoices())
            return BlzFrameIsVisible(crInterface.choiceButton[index])
        end

        ---Check if the specified techtree chunk (by index) is visible or not.
        ---@param techChunk integer
        ---@return boolean
        function crInterface.isTechtreeChunkVisible(techChunk)
            techChunk   = crInterface.getBoundedIntValue(techChunk, 1, GetTechtreeChunkCount())
            return BlzFrameIsVisible(crInterface.techtreeChunk[techChunk])
        end

        ---Check if the specified choice arrow (by direction) is visible or not.
        ---@param isUp boolean
        ---@return boolean
        function crInterface.isChoiceArrowVisible(isUp)
            local index = (isUp and 1) or 2
            return BlzFrameIsVisible(crInterface.choiceArrow[index])
        end

        ---Check if the corresponding techtree chunk directional arrow is visible or not.
        ---@param techChunk integer
        ---@param isUp boolean
        ---@return boolean
        function crInterface.isTechtreeArrowVisible(techChunk, isUp)
            local index     = 0
            techChunk       = crInterface.getBoundedIntValue(techChunk, 1, GetTechtreeChunkCount())
            index           = (techChunk)*2
            if isUp then
                index       = index - 1
            end
            return BlzFrameIsVisible(crInterface.techtreeArrow[index])
        end

        ---Check if the faction name handle is visible or not.
        ---@return boolean
        function crInterface.isFactionNameVisible()
            return BlzFrameIsVisible(crInterface.factFrame)
        end

        ---Check if the specified techtree icon (by index) is visible or not.
        ---@param contextID integer
        ---@return boolean
        function crInterface.isTechtreeIconVisible(contextID)
            return BlzFrameIsVisible(crInterface.techtreeIcons[contextID])
        end

        --  =========================================  --
        --          Visibility Setters API             --
        --  =========================================  --

        ---Convenience method to show and hide the main frame.
        ---@param flag boolean
        function crInterface.setMainVisible(flag)
            BlzFrameSetVisible(crInterface.main, flag)
        end

        ---Convenience method to show and hide the tooltip frame.
        ---@param flag boolean
        function crInterface.setTooltipVisible(flag)
            BlzFrameSetVisible(crInterface.techTooltip, flag)
        end

        ---Convenience method to show and hide the slider frame.
        ---@param flag boolean
        function crInterface.setSliderVisible(flag)
            BlzFrameSetVisible(crInterface.slider, flag)
        end

        ---Convenience method to show and hide the choice button frames.
        ---@param flag boolean
        function crInterface.setChoiceButtonVisible(index, flag)
            index   = crInterface.getBoundedIntValue(index, 1, GetMaxDisplayChoices())
            BlzFrameSetVisible(crInterface.choiceButton[index], flag)
        end

        ---Convenience method to show and hide the techtree chunk / container frames.
        ---@param techChunk integer
        ---@param flag boolean
        function crInterface.setTechtreeChunkVisible(techChunk, flag)
            techChunk       = crInterface.getBoundedIntValue(techChunk, 1, GetTechtreeChunkCount())
            BlzFrameSetVisible(crInterface.techtreeChunk[techChunk], flag)
        end

        ---Convenience method to show and hide the arrow frames that control faction selection.
        ---@param isUp boolean
        ---@param flag boolean
        function crInterface.setChoiceArrowVisible(isUp, flag)
            local index = (isUp and 1) or 2
            BlzFrameSetVisible(crInterface.choiceArrow[index], flag)
        end

        ---Convenience method to show and hide the arrow frames that indicate which techtree icons to display.
        ---@param techChunk integer
        ---@param isUp boolean
        ---@param flag boolean
        function crInterface.setTechtreeArrowVisible(techChunk, isUp, flag)
            techChunk           = crInterface.getBoundedIntValue(techChunk, 1, GetTechtreeChunkCount())
            local index         = (techChunk)*2
            if isUp then
                index           = index - 1
            end
            BlzFrameSetVisible(crInterface.techtreeArrow[index], flag)
        end

        ---Convenience method to show and hide the faction name handle.
        ---@param flag boolean
        function crInterface.setFactionNameVisible(flag)
            BlzFrameSetVisible(crInterface.factFrame, flag)
        end

        ---Convenience method to show and hide the specified techtree icon (by index).
        ---@param contextID integer
        ---@param flag boolean
        function crInterface.setTechtreeIconVisible(contextID, flag)
            BlzFrameSetVisible(crInterface.techtreeIcons[contextID], flag)
        end

        --  =============================================================   --
        --                End External Struct API                           --
        --  =============================================================   --
        do
            ---@param world userdata handle -> originframe
            local function initMainFrame(world)
                --  Assign variables
                crInterface.main            = BlzCreateFrame("CustomRaceMainFrame", world, 0, 0)
                crInterface.iconFrame       = BlzGetFrameByName("CustomRaceFactionDisplayIcon", 0)
                crInterface.descArea        = BlzGetFrameByName("CustomRaceFactionDescArea", 0)
                crInterface.factFrame       = BlzGetFrameByName("CustomRaceFactionName", 0)
                crInterface.confirmFrame    = BlzGetFrameByName("CustomRaceFactionConfirmButton", 0)
                crInterface.choiceFrame     = BlzGetFrameByName("CustomRaceFactionChoiceMain", 0)
                crInterface.techFrame       = BlzGetFrameByName("CustomRaceFactionTechtreeBackdrop", 0)
                crInterface.slider          = BlzGetFrameByName("CustomRaceFactionChoiceScrollbar", 0)
                crInterface.bar             = BlzGetFrameByName("CustomRaceFactionUpdateBar", 0)
                crInterface.barParent       = BlzFrameGetParent(crInterface.bar)

                crInterface.choiceArrow[1]  = BlzGetFrameByName("CustomRaceFactionChoiceScrollbarIncButton", 0)
                crInterface.choiceArrow[2]  = BlzGetFrameByName("CustomRaceFactionChoiceScrollbarDecButton", 0)
                crInterface.iconsPerChunk   = GetTechtreeIconRowMax()*GetTechtreeIconColumnMax()

                --  Prepare actual frame for use.
                BlzFrameSetAbsPoint(crInterface.main, FRAMEPOINT_CENTER, GetMainFrameCenterX(), GetMainFrameCenterY())
                BlzFrameSetTexture(crInterface.bar, GetBarModel(), 0, true)
                BlzFrameSetAlpha(crInterface.bar, R2I(255.0*(1.0 - GetBarTransparency())))
                if not MainFrameInitiallyVisible() then
                    BlzFrameSetVisible(crInterface.main, false)
                end
            end

            local function initChildFrames()
                -- local integer variables
                local i        = 1
                local j        = 0
                local k        = 0
                local row      = GetTechtreeIconRowMax()
                local col      = GetTechtreeIconColumnMax()
                local id       = 0

                -- local float / number variables
                local width    = BlzFrameGetWidth(crInterface.choiceFrame)
                local size     = (BlzFrameGetHeight(crInterface.choiceFrame) - GetChoiceSizeOffset()) / R2I(GetMaxDisplayChoices())
                local dwidth   = 0.0

                -- local framehandle variables
                local tempFrame
                local oldTempFrame

                -- Create the choice buttons.
                while (i <= GetMaxDisplayChoices()) do
                    crInterface.choiceButton[i]     = BlzCreateFrame("CustomRaceFactionChoiceButton", crInterface.choiceFrame, 0, i)
                    id                  = GetFrameIndex(crInterface.choiceButton[i])
                    crInterface.choiceButtonId[id]  = i
                    BlzFrameSetPoint(crInterface.choiceButton[i], FRAMEPOINT_TOP, crInterface.choiceFrame, FRAMEPOINT_TOP, 0, -(GetChoiceSizeOffset() + (i-1)*size))
                    BlzFrameSetSize(crInterface.choiceButton[i], width, size)
                    i   = i + 1
                end

                -- Create the tooltip frame.
                crInterface.techTooltip             = BlzCreateFrame("CustomRaceTechtreeTooltip", crInterface.main, 0, 0)
                crInterface.techTooltipName         = BlzGetFrameByName("CustomRaceTechtreeTooltipName", 0)
                crInterface.techTooltipDesc         = BlzGetFrameByName("CustomRaceTechtreeTooltipNameExtended", 0)
                BlzFrameSetPoint(crInterface.techTooltip, FRAMEPOINT_BOTTOMLEFT, crInterface.techFrame, FRAMEPOINT_TOPRIGHT, GetTechtreeTooltipOffsetX(), GetTechtreeTooltipOffsetY())

                -- Create the techtree chunks and icons
                j = 1
                while (j <= GetTechtreeChunkCount()) do
                    crInterface.techtreeChunk[j]    = BlzCreateFrame("CustomRaceTechtreeChunk", crInterface.techFrame, 0, j)
                    BlzFrameSetSize(crInterface.techtreeChunk[j], BlzFrameGetWidth(crInterface.techFrame), BlzFrameGetHeight(crInterface.techFrame) / I2R(GetTechtreeChunkCount()))
                    if j == 1 then
                        BlzFrameSetPoint(crInterface.techtreeChunk[j], FRAMEPOINT_TOP, crInterface.techFrame, FRAMEPOINT_TOP, 0.0, 0.0)
                    else
                        BlzFrameSetPoint(crInterface.techtreeChunk[j], FRAMEPOINT_TOP, crInterface.techtreeChunk[j - 1], FRAMEPOINT_BOTTOM, 0.0, 0.0)
                    end
                    tempFrame           = BlzGetFrameByName("CustomRaceTechtreeChunkTitle", j)
                    BlzFrameSetText(tempFrame, techName[j])
                    BlzFrameSetSize(tempFrame, BlzFrameGetWidth(crInterface.techFrame),  GetTechtreeChunkTextFrameHeight())
                    BlzFrameSetPoint(tempFrame, FRAMEPOINT_TOP, crInterface.techtreeChunk[j], FRAMEPOINT_TOP, 0.0, 0.0)

                    oldTempFrame        = tempFrame
                    tempFrame           = BlzGetFrameByName("CustomRaceTechtreeChunkHolder", j)
                    BlzFrameSetSize(tempFrame, BlzFrameGetWidth(crInterface.techFrame) - GetTechtreeChunkTextFrameWidth(), BlzFrameGetHeight(crInterface.techtreeChunk[j]) -  GetTechtreeChunkTextFrameHeight())
                    BlzFrameSetPoint(tempFrame, FRAMEPOINT_TOPRIGHT, oldTempFrame,  FRAMEPOINT_BOTTOMRIGHT, 0.0, 0.0)

                    width   = (BlzFrameGetWidth(tempFrame) - 2*GetTechtreeChunkHolderWidthOffset()) / I2R(col)
                    size    = (BlzFrameGetHeight(tempFrame) - 2*GetTechtreeChunkHolderHeightOffset()) / I2R(row)
                    k       = 1
                    while (k <= row) do
                        i   = 1
                        while (i <= col) do
                            id  = (j-1)*(col*row) + (k-1)*col + i
                            crInterface.techtreeIcons[id]   = BlzCreateFrame("CustomRaceFactionTechtreeIcon", tempFrame, 0, id)

                            --  DO NOT DELETE THESE LINES! This ensures that the amount of handle ids
                            --  remains the same across all clients (also a pain to debug).
                            --  Otherwise, desyncs WILL occur at the start of the game.
                            BlzGetFrameByName("CustomRaceFactionTechtreeIconActiveBackdrop", id)
                            BlzGetFrameByName("CustomRaceFactionTechtreeIconBackdrop", id)

                            -- Lua tables are quite the upgrade. Still, for compatibility
                            -- purposes, the syntax remains the same.
                            crInterface.techtreeIconContextId[GetFrameIndex(crInterface.techtreeIcons[id])] = id
                            BlzFrameSetSize(crInterface.techtreeIcons[id], width, size)
                            if i == 1 then
                                if k == 1 then
                                    --  Reposition the first icon above
                                    BlzFrameSetPoint(crInterface.techtreeIcons[id], FRAMEPOINT_TOPLEFT, tempFrame, FRAMEPOINT_TOPLEFT, GetTechtreeChunkHolderWidthOffset(), -GetTechtreeChunkHolderHeightOffset())
                                else
                                    --  First icon already defined. Just move
                                    --  this icon below that.
                                    BlzFrameSetPoint(crInterface.techtreeIcons[id], FRAMEPOINT_TOPLEFT, crInterface.techtreeIcons[id - col], FRAMEPOINT_BOTTOMLEFT, 0.0, 0.0)
                                end
                            else
                                BlzFrameSetPoint(crInterface.techtreeIcons[id], FRAMEPOINT_LEFT, crInterface.techtreeIcons[id - 1], FRAMEPOINT_RIGHT, 0.0, 0.0)
                            end
                            i   = i + 1
                        end
                        k   = k + 1
                    end

                    dwidth              = BlzFrameGetWidth(crInterface.techFrame) - BlzFrameGetWidth(tempFrame)
                    size                = BlzFrameGetHeight(tempFrame) / 2.0
                    dwidth              = RMinBJ(dwidth - GetTechtreeChunkHolderWidthOffset() / 2.0, GetTechtreeArrowMaxWidth())
                    size                = size - GetTechtreeChunkHolderHeightOffset() / 2.0

                    --  Creating the slide arrows
                    id                  = (j-1)*2 + 1
                    crInterface.techtreeArrow[id]   = BlzCreateFrame("CustomRaceButton", crInterface.techtreeChunk[j], 0, id)
                    BlzFrameSetSize(crInterface.techtreeArrow[id], dwidth, size)
                    BlzFrameSetPoint(crInterface.techtreeArrow[id], FRAMEPOINT_TOPRIGHT, tempFrame, FRAMEPOINT_TOPLEFT, GetTechtreeChunkHolderWidthOffset(), -GetTechtreeChunkHolderHeightOffset())
                    BlzFrameSetTexture(BlzGetFrameByName("CustomRaceButtonBG", id), GetUpArrowButtonModel(), 0, true)
                    BlzFrameSetTexture(BlzGetFrameByName("CustomRaceButtonPushedBG", id), GetUpArrowButtonModel(), 0, true)
                    BlzFrameSetTexture(BlzGetFrameByName("CustomRaceButtonDBG", id), GetUpArrowButtonModel(), 0, true)
                    BlzFrameSetTexture(BlzGetFrameByName("CustomRaceButtonPushedDBG", id), GetUpArrowButtonModel(), 0, true)

                    id                  = id + 1
                    crInterface.techtreeArrow[id]   = BlzCreateFrame("CustomRaceButton", crInterface.techtreeChunk[j], 0, id)
                    BlzFrameSetSize(crInterface.techtreeArrow[id], dwidth, size)
                    BlzFrameSetPoint(crInterface.techtreeArrow[id], FRAMEPOINT_BOTTOMRIGHT, tempFrame, FRAMEPOINT_BOTTOMLEFT, GetTechtreeChunkHolderWidthOffset(), GetTechtreeChunkHolderHeightOffset())
                    BlzFrameSetTexture(BlzGetFrameByName("CustomRaceButtonBG", id), GetDownArrowButtonModel(), 0, true)
                    BlzFrameSetTexture(BlzGetFrameByName("CustomRaceButtonPushedBG", id), GetDownArrowButtonModel(), 0, true)
                    BlzFrameSetTexture(BlzGetFrameByName("CustomRaceButtonDBG", id), GetDownArrowButtonModel(), 0, true)
                    BlzFrameSetTexture(BlzGetFrameByName("CustomRaceButtonPushedDBG", id), GetDownArrowButtonModel(), 0, true)
                    j   = j + 1
                end
                tempFrame       = nil
                oldTempFrame    = nil
            end

            local function init()
                local world         = BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
                if not BlzLoadTOCFile(GetTOCPath()) then
                    if IN_DEBUG_MODE then
                        Debugger.prepWarning("CustomRaceInterface.init", "Unable to load toc path. Aborting! \n    (" + GetTOCPath() + ")")
                        Debugger.raiseWarning("CustomRaceInterface")
                    end
                    return
                end
                InitChunkNames()
                initMainFrame(world)
                initChildFrames()
            end

            -- This initializer assumes that you have imported Bribe's Global Initialization script
            -- into your map.
            OnMainInit(
            function()
                --- Prevent future callbacks.
                init()
                if FrameLoaderAdd then
                    FrameLoaderAdd(init)
                end
            end)
        end
    end
end