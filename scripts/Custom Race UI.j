library CustomRaceUI requires /*

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
    |   struct CustomRaceInterface
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
    |       framehandle array techtreeIcons
    |       framehandle array techtreeChunk
    |       framehandle array techtreeArrow
    |       framehandle array choiceArrow
    |       framehandle array choiceButton
    |
     ---------------------------------------------------------------------------
*/

globals
    private constant boolean IN_DEBUG_MODE  = true
endglobals

private constant function DebugFrameModel takes nothing returns string
    return "ReplaceableTextures\\CommandButtons\\BTNGhoul.tga"
endfunction
private constant function GetTOCPath takes nothing returns string
    return "war3mapImported\\CustomRaceTOC.toc"
endfunction
private constant function GetUpArrowButtonModel takes nothing returns string
    return "UI\\Widgets\\Glues\\SinglePlayerSkirmish-ScrollBarUpButton.blp"
endfunction
private constant function GetDownArrowButtonModel takes nothing returns string
    return "UI\\Widgets\\Glues\\SinglePlayerSkirmish-ScrollBarDownButton.blp"
endfunction
private constant function MainFrameInitiallyVisible takes nothing returns boolean
    return false
endfunction
private constant function GetTechtreeChunkTextFrameWidth takes nothing returns real
    return 0.024
endfunction
private constant function GetTechtreeChunkTextFrameHeight takes nothing returns real
    return 0.018
endfunction
private constant function GetTechtreeChunkHolderWidthOffset takes nothing returns real
    return 0.004
endfunction
private constant function GetTechtreeChunkHolderHeightOffset takes nothing returns real
    return 0.004
endfunction
private constant function GetTechtreeArrowMaxWidth takes nothing returns real
    return 0.032
endfunction

//  ====================================================    //
//                  CONFIGURATION SECTION                   //
//  ====================================================    //
globals
    public string array techName
    constant integer    TECHTREE_CHUNK_UNIT     = 1
    constant integer    TECHTREE_CHUNK_BUILDING = 2
    constant integer    TECHTREE_CHUNK_HEROES   = 3
    constant integer    TECHTREE_CHUNK_UPGRADES = 4
endglobals

public constant  function GetMainFrameCenterX takes nothing returns real
    return 0.342
endfunction
public constant  function GetMainFrameCenterY takes nothing returns real
    return 0.338
endfunction
private constant function GetTechtreeTooltipOffsetX takes nothing returns real
    return 0.016
endfunction
private constant function GetTechtreeTooltipOffsetY takes nothing returns real
    return -0.06
endfunction
public constant  function GetMaxDisplayChoices takes nothing returns integer
    return 3
endfunction
private constant function GetChoiceSizeOffset takes nothing returns real
    return 0.003
endfunction
public constant function GetTechtreeChunkCount takes nothing returns integer
    return 2
endfunction
public constant function GetTechtreeIconColumnMax takes nothing returns integer
    return 4
endfunction
public constant function GetTechtreeIconRowMax takes nothing returns integer
    return 2
endfunction

private constant function GetBarModel takes nothing returns string
    return "ReplaceableTextures\\Teamcolor\\Teamcolor01.tga"
endfunction
private constant function GetBarTransparency takes nothing returns real
    return 0.55
endfunction
private function InitChunkNames takes nothing returns nothing
    set techName[TECHTREE_CHUNK_UNIT]       = "Units:"
    set techName[TECHTREE_CHUNK_BUILDING]   = "Buildings:"
    set techName[TECHTREE_CHUNK_HEROES]     = "Heroes:"
    set techName[TECHTREE_CHUNK_UPGRADES]   = "Upgrades:"
endfunction
//  ====================================================    //
//                END CONFIGURATION SECTION                 //
//  ====================================================    //

//  Too lazy to use a hashtable here, so this hashing function will do.
//  Since there are only about 3-4 (8+ is pushing it) buttons in total,
//  the chance of a collision in index entry might as well be 0. (there
//  is a chance, but it is statistically improbable.)
private function GetFrameIndex takes framehandle whichButton returns integer
    return ModuloInteger(GetHandleId(whichButton) - 0x100000, 0x8000)
endfunction

static if IN_DEBUG_MODE then
private struct Debugger extends array
    private  static integer     warningRaised       = 0
    private  static string      array warning

    static method prepWarning takes string source, string msg returns nothing
        set warningRaised           = warningRaised + 1
        set warning[warningRaised]  = "\n    (" + I2S(warningRaised) + /*
                                   */ ") In " + source + ": (" + msg + ")."
    endmethod

    static method raiseWarning takes string source returns nothing
        local string msg    = source + ": Warning Raised!"
        local integer i     = 1
        if warningRaised < 1 then
            return
        endif
        loop
            exitwhen i > warningRaised
            set msg = msg + warning[i]
            set i   = i + 1
        endloop
        set warningRaised   = 0
        call DisplayTimedTextToPlayer(GetLocalPlayer(), 0.0, 0.0, 60.0, msg)
    endmethod

    static method warningReady takes nothing returns boolean
        return warningRaised > 0
    endmethod
endstruct
endif

struct CustomRaceInterface extends array
    readonly static framehandle main                = null
    readonly static framehandle iconFrame           = null
    readonly static framehandle descArea            = null
    readonly static framehandle factFrame           = null
    readonly static framehandle confirmFrame        = null
    readonly static framehandle choiceFrame         = null
    readonly static framehandle techFrame           = null
    readonly static framehandle slider              = null
    readonly static framehandle bar                 = null
    readonly static framehandle barParent           = null
    readonly static framehandle techTooltip         = null
    readonly static framehandle techTooltipName     = null
    readonly static framehandle techTooltipDesc     = null

    readonly static framehandle array techtreeIcons
    readonly static framehandle array techtreeChunk
    readonly static framehandle array techtreeArrow
    readonly static framehandle array choiceArrow
    readonly static framehandle array choiceButton
    readonly static integer     array choiceButtonId
    readonly static integer     array techtreeIconContextId

    readonly static integer     iconsPerChunk       = 0
    readonly static integer     sliderMinValue      = 0
    readonly static integer     sliderMaxValue      = 1
    readonly static string      iconTexture         = ""

    private static method getBoundedRealValue takes real a, real max, real min returns real
        local real temp = 0.0
        if max < min then
            set temp    = max
            set max     = min
            set min     = temp
        endif
        if a > max then
            static if IN_DEBUG_MODE then
                call Debugger.prepWarning("getBoundedRealValue", R2S(a) + " is greater than the maximum value " + R2S(max))
            endif
            set a   = max
        endif
        if a < min then
            static if IN_DEBUG_MODE then
                call Debugger.prepWarning("getBoundedRealValue", R2S(a) + " is less than the minimum value " + R2S(min))
            endif
            set a   = min
        endif
        return a
    endmethod

    private static method getBoundedIntValue takes integer a, integer max, integer min returns integer
        local integer temp = 0
        if max < min then
            set temp    = max
            set max     = min
            set min     = temp
        endif
        if a > max then
            static if IN_DEBUG_MODE then
                call Debugger.prepWarning("getBoundedIntValue", I2S(a) + " is greater than the maximum value " + I2S(max))
            endif
            set a   = max
        endif
        if a < min then
            static if IN_DEBUG_MODE then
                call Debugger.prepWarning("getBoundedIntValue", I2S(a) + " is less than the minimum value " + I2S(min))
            endif
            set a   = min
        endif
        return a
    endmethod

    private static method chunkInfo2Index takes integer techChunk, integer row, integer col returns integer
        set techChunk   = getBoundedIntValue(techChunk, 1, GetTechtreeChunkCount())
        static if IN_DEBUG_MODE then
            call Debugger.raiseWarning("chunkInfo2Index (techChunk)")
        endif
        set row         = getBoundedIntValue(row, 1, GetTechtreeIconRowMax())
        static if IN_DEBUG_MODE then
            call Debugger.raiseWarning("chunkInfo2Index (row)")
        endif
        set col         = getBoundedIntValue(col, 1, GetTechtreeIconColumnMax())
        static if IN_DEBUG_MODE then
            call Debugger.raiseWarning("chunkInfo2Index (col)")
        endif
        return (techChunk-1)*GetTechtreeIconRowMax()*GetTechtreeIconColumnMax() + /*
            */ (row-1)*GetTechtreeIconColumnMax() + col
    endmethod

    //  =============================================================   //
    //                      External Struct API                         //
    //  =============================================================   //
    //  ==================  //
    //      Getter API      //
    //  ==================  //
    static method getTechtreeIcon takes integer techChunk, integer row, integer col returns framehandle
        return techtreeIcons[chunkInfo2Index(techChunk, row, col)]
    endmethod

    static method getTechtreeIconRaw takes integer index returns framehandle
        return techtreeIcons[index]
    endmethod

    static method getChoiceButton takes integer index returns framehandle
        return choiceButton[index]
    endmethod

    static method getTechtreeArrow takes integer techChunk, boolean isUp returns framehandle
        set techChunk   = getBoundedIntValue(techChunk, 1, GetMaxDisplayChoices())
        if isUp then
            return techtreeArrow[2*(techChunk-1) + 1]
        endif
        return techtreeArrow[2*(techChunk)]
    endmethod

    static method getTechtreeArrowID takes framehandle arrow returns integer
        local integer i = 1
        local integer j = GetTechtreeChunkCount()*2
        loop
            exitwhen i > j
            if techtreeArrow[i] == arrow then
                return i
            endif
            set i = i + 1
        endloop
        return 0
    endmethod

    static method getChoiceArrow takes boolean isUp returns framehandle
        if isUp then
            return choiceArrow[1]
        endif
        return choiceArrow[2]
    endmethod

    static method getChoiceArrowID takes framehandle arrow returns integer
        if arrow == choiceArrow[1] then
            return 1
        elseif arrow == choiceArrow[2] then
            return 2
        endif
        return 0
    endmethod

    static method getChoiceButtonID takes framehandle choice returns integer
        return choiceButtonId[GetFrameIndex(choice)]
    endmethod

    static method getTechtreeIconID takes framehandle icon returns integer
        return techtreeIconContextId[GetFrameIndex(icon)]
    endmethod

    static method getSliderValue takes nothing returns integer
        return R2I(BlzFrameGetValue(slider) + 0.01)
    endmethod

    static method getChunkFromIndex takes integer id returns integer
        return ((id - 1) / iconsPerChunk) + 1
    endmethod
    //  ==================  //
    //      Setter API      //
    //  ==================  //
    static method setTooltipName takes string name returns nothing
        if name == "" then
            set name    = "Unit Name Missing!"
        endif
        call BlzFrameSetText(techTooltipName, name)
    endmethod

    static method setTooltipDesc takes string desc returns nothing
        if desc == "" then
            set desc    = "Tooltip Missing!"
        endif
        call BlzFrameSetText(techTooltipDesc, desc)
    endmethod

    static method setDescription takes string content returns nothing
        call BlzFrameSetText(descArea, content)
    endmethod

    static method setChoiceName takes integer index, string name returns nothing
        set index   = getBoundedIntValue(index, 1, GetMaxDisplayChoices())
        if name == "" then
            set name    = "Factionless"
        endif
        call BlzFrameSetText(choiceButton[index], name)
    endmethod

    static method setTechtreeIconDisplay takes integer techChunk, integer row, integer col, string display returns nothing
        local integer index     = chunkInfo2Index(techChunk, row, col)
        local framehandle icon  = BlzGetFrameByName("CustomRaceFactionTechtreeIconActiveBackdrop", index)
        local framehandle pIcon = BlzGetFrameByName("CustomRaceFactionTechtreeIconBackdrop", index)
        call BlzFrameSetTexture(icon, display, 0, true)
        call BlzFrameSetTexture(pIcon, display, 0, true)
        set pIcon               = null
        set icon                = null
    endmethod

    static method setTechtreeIconDisplayEx takes framehandle techIcon, string display returns nothing
        local integer index     = techtreeIconContextId[GetFrameIndex(techIcon)]
        local framehandle icon
        local framehandle pIcon
        if index == 0 then
            return
        endif
        set icon    = BlzGetFrameByName("CustomRaceFactionTechtreeIconActiveBackdrop", index)
        set pIcon   = BlzGetFrameByName("CustomRaceFactionTechtreeIconBackdrop", index)
        call BlzFrameSetTexture(icon, display, 0, true)
        call BlzFrameSetTexture(pIcon, display, 0, true)
        set pIcon               = null
        set icon                = null
    endmethod

    static method setTechtreeIconDisplayByID takes integer contextID, string display returns nothing
        local framehandle icon  = BlzGetFrameByName("CustomRaceFactionTechtreeIconActiveBackdrop", contextID)
        local framehandle pIcon = BlzGetFrameByName("CustomRaceFactionTechtreeIconBackdrop", contextID)
        call BlzFrameSetTexture(icon, display, 0, true)
        call BlzFrameSetTexture(pIcon, display, 0, true)
        set pIcon               = null
        set icon                = null
    endmethod
    
    //  Values range from 0.0 - 1.0 with 1.0 filling up the entire bar
    //  and 0.0 being completely empty.
    static method setBarProgress takes real amount returns nothing
        set amount  = getBoundedRealValue(amount, 1.0, 0.0)
        call BlzFrameSetSize(bar, BlzFrameGetWidth(barParent)*(amount), BlzFrameGetHeight(barParent))
    endmethod

    //  Values range from 0.0 - 1.0 with 1.0 being completely visible
    //  and 0.0 being completely invisible
    static method setMainAlpha takes real ratio returns nothing
        set ratio   = getBoundedRealValue(ratio, 1.0, 0.0)
        call BlzFrameSetAlpha(main, R2I(255.0*ratio))
        if iconTexture == "" and BlzFrameIsVisible(iconFrame) then
            call BlzFrameSetVisible(iconFrame, false)
        endif
        call BlzFrameSetAlpha(bar, R2I(255.0*ratio*(1.0 - GetBarTransparency())))
    endmethod

    //  Displays the representative faction image to the top-left
    //  of the main frame. Adding an empty string automatically
    //  hides the frame.
    static method setFactionDisplay takes string imagePath returns nothing
        set iconTexture = imagePath
        if imagePath == "" and BlzFrameIsVisible(iconFrame) then
            call BlzFrameSetVisible(iconFrame, false)
        elseif (imagePath != "") and (not BlzFrameIsVisible(iconFrame)) then
            call BlzFrameSetVisible(iconFrame, true)
        endif
        call BlzFrameSetTexture(iconFrame, imagePath, 0, true)
    endmethod

    static method setFactionName takes string name returns nothing
        if name == "" then
            set name    = "Faction Name"
        endif
        call BlzFrameSetText(factFrame, name)
    endmethod

    static method setMainPos takes real x, real y returns nothing
        call BlzFrameSetAbsPoint(main, FRAMEPOINT_CENTER, x, y)
    endmethod

    static method setSliderValue takes integer value returns nothing
        call BlzFrameSetValue(slider, value)
    endmethod

    static method setSliderMaxValue takes integer value returns nothing
        local real preValue = BlzFrameGetValue(slider)
        local real preMax   = sliderMaxValue
        set value           = IMaxBJ(value, 1)
        set sliderMaxValue  = value
        call BlzFrameSetMinMaxValue(slider, 0.0, value)
        call BlzFrameSetValue(slider, preValue + value - preMax)
    endmethod

    //  ==============================  //
    //      Boolean State Check API     //
    //  ==============================  //
    static method isMainVisible takes nothing returns boolean
        return BlzFrameIsVisible(main)
    endmethod

    static method isTooltipVisible takes nothing returns boolean
        return BlzFrameIsVisible(techTooltip)
    endmethod

    static method isSliderVisible takes nothing returns boolean
        return BlzFrameIsVisible(slider)
    endmethod

    static method isChoiceButtonVisible takes integer index returns boolean
        set index   = getBoundedIntValue(index, 1, GetMaxDisplayChoices())
        return BlzFrameIsVisible(choiceButton[index])
    endmethod

    static method isTechtreeChunkVisible takes integer techChunk returns boolean
        set techChunk       = getBoundedIntValue(techChunk, 1, GetTechtreeChunkCount())
        return BlzFrameIsVisible(techtreeChunk[techChunk])
    endmethod

    static method isChoiceArrowVisible takes boolean isUp returns boolean
        if isUp then
            return BlzFrameIsVisible(choiceArrow[1])
        endif
        return BlzFrameIsVisible(choiceArrow[2])
    endmethod

    static method isTechtreeArrowVisible takes integer techChunk, boolean isUp returns boolean
        local integer index = 0
        set techChunk       = getBoundedIntValue(techChunk, 1, GetTechtreeChunkCount())
        set index           = (techChunk)*2
        if isUp then
            set index       = index - 1
        endif
        return BlzFrameIsVisible(techtreeArrow[index])
    endmethod

    static method isFactionNameVisible takes nothing returns boolean
        return BlzFrameIsVisible(factFrame)
    endmethod

    static method isTechtreeIconVisible takes integer contextID returns boolean
        return BlzFrameIsVisible(techtreeIcons[contextID])
    endmethod
    //  ==============================  //
    //          Regular API             //
    //  ==============================  //
    static method setMainVisible takes boolean flag returns nothing
        call BlzFrameSetVisible(main, flag)
    endmethod

    static method setTooltipVisible takes boolean flag returns nothing
        call BlzFrameSetVisible(techTooltip, flag)
    endmethod

    static method setSliderVisible takes boolean flag returns nothing
        call BlzFrameSetVisible(slider, flag)
    endmethod

    static method setChoiceButtonVisible takes integer index, boolean flag returns nothing
        set index   = getBoundedIntValue(index, 1, GetMaxDisplayChoices())
        call BlzFrameSetVisible(choiceButton[index], flag)
    endmethod

    static method setTechtreeChunkVisible takes integer techChunk, boolean flag returns nothing
        set techChunk       = getBoundedIntValue(techChunk, 1, GetTechtreeChunkCount())
        call BlzFrameSetVisible(techtreeChunk[techChunk], flag)
    endmethod

    static method setChoiceArrowVisible takes boolean isUp, boolean flag returns nothing
        if isUp then
            call BlzFrameSetVisible(choiceArrow[1], flag)
        endif
        call BlzFrameSetVisible(choiceArrow[2], flag)
    endmethod

    static method setTechtreeArrowVisible takes integer techChunk, boolean isUp, boolean flag returns nothing
        local integer index = 0
        set techChunk       = getBoundedIntValue(techChunk, 1, GetTechtreeChunkCount())
        set index           = (techChunk)*2
        if isUp then
            set index       = index - 1
        endif
        call BlzFrameSetVisible(techtreeArrow[index], flag)
    endmethod

    static method setFactionNameVisible takes boolean flag returns nothing
        call BlzFrameSetVisible(factFrame, flag)
    endmethod

    static method setTechtreeIconVisible takes integer contextID, boolean flag returns nothing
        call BlzFrameSetVisible(techtreeIcons[contextID], flag)
    endmethod

    //  =============================================================   //
    //                End External Struct API                           //
    //  =============================================================   //

    private static method initMainFrame takes framehandle world returns nothing
        //  Assign variables
        set main            = BlzCreateFrame("CustomRaceMainFrame", world, 0, 0)
        set iconFrame       = BlzGetFrameByName("CustomRaceFactionDisplayIcon", 0)
        set descArea        = BlzGetFrameByName("CustomRaceFactionDescArea", 0)
        set factFrame       = BlzGetFrameByName("CustomRaceFactionName", 0)
        set confirmFrame    = BlzGetFrameByName("CustomRaceFactionConfirmButton", 0)
        set choiceFrame     = BlzGetFrameByName("CustomRaceFactionChoiceMain", 0)
        set techFrame       = BlzGetFrameByName("CustomRaceFactionTechtreeBackdrop", 0)
        set slider          = BlzGetFrameByName("CustomRaceFactionChoiceScrollbar", 0)
        set bar             = BlzGetFrameByName("CustomRaceFactionUpdateBar", 0)
        set barParent       = BlzFrameGetParent(bar)

        set choiceArrow[1]  = BlzGetFrameByName("CustomRaceFactionChoiceScrollbarIncButton", 0)
        set choiceArrow[2]  = BlzGetFrameByName("CustomRaceFactionChoiceScrollbarDecButton", 0)
        set iconsPerChunk   = GetTechtreeIconRowMax()*GetTechtreeIconColumnMax()

        //  Prepare actual frame for use.
        call BlzFrameSetAbsPoint(main, FRAMEPOINT_CENTER, GetMainFrameCenterX(), GetMainFrameCenterY())
        call BlzFrameSetTexture(bar, GetBarModel(), 0, true)
        call BlzFrameSetAlpha(bar, R2I(255.0*(1.0 - GetBarTransparency())))
        if not MainFrameInitiallyVisible() then
            call BlzFrameSetVisible(main, false)
        endif
    endmethod

    private static method initChildFrames takes nothing returns nothing
        local integer i     = 1
        local integer j     = 0
        local integer k     = 0
        local integer row   = GetTechtreeIconRowMax()
        local integer col   = GetTechtreeIconColumnMax()
        local integer id    = 0
        local real width    = BlzFrameGetWidth(choiceFrame)
        local real size     = (BlzFrameGetHeight(choiceFrame) - GetChoiceSizeOffset()) / R2I(GetMaxDisplayChoices())
        local real dwidth   = 0.0
        local framehandle tempFrame
        local framehandle oldTempFrame
        //  Create the choice buttons.
        loop
            exitwhen i > GetMaxDisplayChoices()
            set choiceButton[i]     = BlzCreateFrame("CustomRaceFactionChoiceButton", choiceFrame, /*
                                                   */ 0, i)
            set id                  = GetFrameIndex(choiceButton[i])
            set choiceButtonId[id]  = i
            call BlzFrameSetPoint(choiceButton[i], FRAMEPOINT_TOP, choiceFrame, FRAMEPOINT_TOP, 0, /*
                             */ -(GetChoiceSizeOffset() + (i-1)*size))
            call BlzFrameSetSize(choiceButton[i], width, size)
            set i                   = i + 1
        endloop

        //  Create the tooltip frame.
        set techTooltip             = BlzCreateFrame("CustomRaceTechtreeTooltip", main, 0, 0)
        set techTooltipName         = BlzGetFrameByName("CustomRaceTechtreeTooltipName", 0)
        set techTooltipDesc         = BlzGetFrameByName("CustomRaceTechtreeTooltipNameExtended", 0)
        call BlzFrameSetPoint(techTooltip, FRAMEPOINT_BOTTOMLEFT, techFrame, FRAMEPOINT_TOPRIGHT, /*
                           */ GetTechtreeTooltipOffsetX(), GetTechtreeTooltipOffsetY())

        //  Create the techtree chunks and icons
        set j = 1
        loop
            exitwhen j > GetTechtreeChunkCount()
            set techtreeChunk[j]    = BlzCreateFrame("CustomRaceTechtreeChunk", techFrame, 0, j)
            call BlzFrameSetSize(techtreeChunk[j], BlzFrameGetWidth(techFrame), /*
                              */ BlzFrameGetHeight(techFrame) / I2R(GetTechtreeChunkCount()))
            if j == 1 then
                call BlzFrameSetPoint(techtreeChunk[j], FRAMEPOINT_TOP, techFrame, /*
                                 */ FRAMEPOINT_TOP, 0.0, 0.0)
            else
                call BlzFrameSetPoint(techtreeChunk[j], FRAMEPOINT_TOP, techtreeChunk[j - 1], /*
                                 */ FRAMEPOINT_BOTTOM, 0.0, 0.0)
            endif
            set tempFrame           = BlzGetFrameByName("CustomRaceTechtreeChunkTitle", j)
            call BlzFrameSetText(tempFrame, techName[j])
            call BlzFrameSetSize(tempFrame, BlzFrameGetWidth(techFrame), /*
                              */ GetTechtreeChunkTextFrameHeight())
            call BlzFrameSetPoint(tempFrame, FRAMEPOINT_TOP, techtreeChunk[j], /*
                               */ FRAMEPOINT_TOP, 0.0, 0.0)

            set oldTempFrame        = tempFrame
            set tempFrame           = BlzGetFrameByName("CustomRaceTechtreeChunkHolder", j)
            call BlzFrameSetSize(tempFrame, BlzFrameGetWidth(techFrame) - /*
                              */ GetTechtreeChunkTextFrameWidth() , /*
                              */ BlzFrameGetHeight(techtreeChunk[j]) - /*
                              */ GetTechtreeChunkTextFrameHeight())
            call BlzFrameSetPoint(tempFrame, FRAMEPOINT_TOPRIGHT, oldTempFrame, /*
                               */ FRAMEPOINT_BOTTOMRIGHT, 0.0, 0.0)

            set width   = (BlzFrameGetWidth(tempFrame) - 2*GetTechtreeChunkHolderWidthOffset()) / I2R(col)
            set size    = (BlzFrameGetHeight(tempFrame) - 2*GetTechtreeChunkHolderHeightOffset()) / I2R(row)
            set k       = 1
            loop
                exitwhen k > row
                set i   = 1
                loop
                    exitwhen i > col
                    set id  = (j-1)*(col*row) + (k-1)*col + i
                    set techtreeIcons[id]   = BlzCreateFrame("CustomRaceFactionTechtreeIcon", /*
                                                           */ tempFrame, 0, id)
                    //  DO NOT DELETE THESE LINES! This ensures that the amount of handle ids
                    //  remains the same across all clients (also a pain to debug). (Relevant in JASS)
                    call BlzGetFrameByName("CustomRaceFactionTechtreeIconActiveBackdrop", id)
                    call BlzGetFrameByName("CustomRaceFactionTechtreeIconBackdrop", id)
                    
                    //  Again, too lazy to use hashtables here.
                    set techtreeIconContextId[GetFrameIndex(techtreeIcons[id])] = id
                    call BlzFrameSetSize(techtreeIcons[id], width, size)
                    if i == 1 then
                        if k == 1 then
                            //  Reposition the first icon above
                            call BlzFrameSetPoint(techtreeIcons[id], FRAMEPOINT_TOPLEFT, /*
                                               */ tempFrame, FRAMEPOINT_TOPLEFT, /*
                                               */ GetTechtreeChunkHolderWidthOffset(), /*
                                               */ -GetTechtreeChunkHolderHeightOffset())
                        else
                            //  First icon already defined. Just move
                            //  this icon below that.
                            call BlzFrameSetPoint(techtreeIcons[id], FRAMEPOINT_TOPLEFT, /*
                                               */ techtreeIcons[id - col], FRAMEPOINT_BOTTOMLEFT, /*
                                               */ 0.0, 0.0)
                        endif
                    else
                        call BlzFrameSetPoint(techtreeIcons[id], FRAMEPOINT_LEFT, /*
                                           */ techtreeIcons[id - 1], FRAMEPOINT_RIGHT, /*
                                           */ 0.0, 0.0)
                    endif
                    set i   = i + 1
                endloop
                set k   = k + 1
            endloop

            set dwidth              = BlzFrameGetWidth(techFrame) - BlzFrameGetWidth(tempFrame)
            set size                = BlzFrameGetHeight(tempFrame) / 2.0
            set dwidth              = RMinBJ(dwidth - GetTechtreeChunkHolderWidthOffset() / 2.0, /*
                                          */ GetTechtreeArrowMaxWidth())
            set size                = size - GetTechtreeChunkHolderHeightOffset() / 2.0

            //  Creating the slide arrows
            set id                  = (j-1)*2 + 1
            set techtreeArrow[id]   = BlzCreateFrame("CustomRaceButton", techtreeChunk[j], 0, id)
            call BlzFrameSetSize(techtreeArrow[id], dwidth, size)
            call BlzFrameSetPoint(techtreeArrow[id], FRAMEPOINT_TOPRIGHT, tempFrame, FRAMEPOINT_TOPLEFT, /*
                               */ GetTechtreeChunkHolderWidthOffset(), /*
                               */ -GetTechtreeChunkHolderHeightOffset())
            call BlzFrameSetTexture(BlzGetFrameByName("CustomRaceButtonBG", id), /*
                                 */ GetUpArrowButtonModel(), 0, true) 
            call BlzFrameSetTexture(BlzGetFrameByName("CustomRaceButtonPushedBG", id), /*
                                 */ GetUpArrowButtonModel(), 0, true)
            call BlzFrameSetTexture(BlzGetFrameByName("CustomRaceButtonDBG", id), /*
                                 */ GetUpArrowButtonModel(), 0, true)
            call BlzFrameSetTexture(BlzGetFrameByName("CustomRaceButtonPushedDBG", id), /*
                                 */ GetUpArrowButtonModel(), 0, true)

            set id                  = id + 1
            set techtreeArrow[id]   = BlzCreateFrame("CustomRaceButton", techtreeChunk[j], 0, id)
            call BlzFrameSetSize(techtreeArrow[id], dwidth, size)
            call BlzFrameSetPoint(techtreeArrow[id], FRAMEPOINT_BOTTOMRIGHT, tempFrame, FRAMEPOINT_BOTTOMLEFT, /*
                               */ GetTechtreeChunkHolderWidthOffset(), /*
                               */ GetTechtreeChunkHolderHeightOffset())
            call BlzFrameSetTexture(BlzGetFrameByName("CustomRaceButtonBG", id), /*
                                 */ GetDownArrowButtonModel(), 0, true)
            call BlzFrameSetTexture(BlzGetFrameByName("CustomRaceButtonPushedBG", id), /*
                                 */ GetDownArrowButtonModel(), 0, true)
            call BlzFrameSetTexture(BlzGetFrameByName("CustomRaceButtonDBG", id), /*
                                 */ GetDownArrowButtonModel(), 0, true)
            call BlzFrameSetTexture(BlzGetFrameByName("CustomRaceButtonPushedDBG", id), /*
                                 */ GetDownArrowButtonModel(), 0, true)
            set j   = j + 1
        endloop
        set tempFrame       = null
        set oldTempFrame    = null
    endmethod

    private static method init takes nothing returns nothing
        local framehandle world = BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
        if not BlzLoadTOCFile(GetTOCPath()) then
            static if IN_DEBUG_MODE then
                call Debugger.prepWarning("thistype.init", "Unable to load toc path. Aborting! \n    (" + GetTOCPath() + ")")
                call Debugger.raiseWarning("thistype")
            endif
            return
        endif
        call InitChunkNames()
        call thistype.initMainFrame(world)
        call thistype.initChildFrames()
        static if LIBRARY_FrameLoader then
            call FrameLoaderAdd(function thistype.init)
        endif
    endmethod

    implement Init
endstruct

endlibrary