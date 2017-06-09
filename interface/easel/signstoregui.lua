------------------
--Core Fucntions--
------------------

function init()
  self.canvas = widget.bindCanvas("scriptCanvas")

  widget.focus("scriptCanvas")

  --I'd make this more unique with the world name, but the seem to have removed world.info()
  --Using world.get/set properties to store persistent data (sign state and templates) between sessions
  --I suppose if an outpost is going to do this stuff, the storage process will be much streamlined
  uniqueEaselIdentifier = "Easel@" .. world.entityPosition(pane.sourceEntity())[1] ..  world.entityPosition(pane.sourceEntity())[2]
  if world.getProperty(uniqueEaselIdentifier.."storage") ~= nil then
    storage = world.getProperty(uniqueEaselIdentifier.."storage")
    --sb.logInfo("World Storage Found: %s", world.getProperty(uniqueEaselIdentifier.."storage"))
    templates = world.getProperty(uniqueEaselIdentifier.."templates")
    --sb.logInfo("World Templates Found: %s", world.getProperty(uniqueEaselIdentifier.."templates"))
  else
    storage = {}
    templates = {}
  end

  --all "storage." and "template." variables are supposed to be permanent, while "self." or un-prefixed variables are session-specific

  templates["fromContainer"] = nil
  storage.currentFrame = storage.currentFrame or 1
  if storage.signPixels == nil then
    storage.signPixels =  {{}}
    for x=1,32 do
      storage.signPixels[storage.currentFrame][x] = {}
      for y=1,8 do
        storage.signPixels[storage.currentFrame][x][y] = 0
      end
    end
  end
  storage.signName = storage.signName or "Sign"
  storage.signDirectiveStrings = storage.signDirectiveStrings or {}
  storage.frameTypes = {
    {"gold", "b79c40FF", "a58038FF"},
    {"wood", "754c23FF", "472b13FF" },
    {"grey" ,"808080FF", "555555FF"},
    {"white" ,"C6D2D4FF","959EA2FF"},
    {"black" ,"383838FF","151515FF"}
  }
  storage.backingTypes = {"blank" , "parchment", "blackboard", "glass", "none", "hazard"}
  --Anchors and Offsets. All rendered parts of the ui are given their positions here, with a personal offset (scanvasButtonOffsets)
  --applied to a more general anchor. Makes it easier to bundle and shift bits around.

  --Anchors are pure {x,y}
  canvasAnchors = {
    ["templates"] = {7, 8},
    ["main"] = {70,2},
    ["color"] = {294,8},
    ["colorWindow"] = {25,5},
    ["errorWindow"] = {0,-15}
  }
  canvasButtonOffsets = {
  --"S:__" buttons are statics, ignored for button finding, just there for a consistent point-of-access when moving stuff
  --The others have {x, y, x+xsize-1, y+ysize-1}
  --Why -1? just because I use <= in the button detection. either way some parts owuld need offsets.
    ["S:digit11"] = {"main", 158, 9},
    ["S:digit12"] = {"main", 162, 9},
    ["S:digit21"] = {"main", 158, 1},
    ["S:digit22"] = {"main", 162, 1},
    ["frameLeft"] = {"main", 135, 3, 135+11, 3+11},
    ["frameRight"] = {"main", 172, 3, 172+11, 3+11},
    ["frameAdd"] = {"main", 148, 8, 148+11, 8+11},
    ["frameDelete"] = {"main", 148, 0, 148+11, 0+11},
    ["shiftLeft"] = {"main", -3, 48, -3+10, 48+11},
    ["pixelPress"] = {"main", 12, 30, 12+191, 30+47},
    ["framePress"] = {"main", 0, 18, 0+215, 18+71},
    ["shiftUp"] = {"main", 102.5, 83, 102.5+11, 83+10},
    ["shiftRight"] = {"main", 209, 48, 209+10, 48+11},
    ["shiftDown"] = {"main", 102.5, 15, 102.5+11, 15+10},
    ["templateSlotCopy"] = {"templates", 74, -7, 74+17, -7+17},
    ["templateSlotScanButton"] = {"templates", 90, -5, 90+57, -5+14},
    --["iconGrab"] = {"main", -96, 18, -96+35, 18+11},
    ["dumpPress"] = {"templates", 0, 70, 0+54, 70+14},
    ["clearPress"] = {"templates", 0, 47, 0+54, 47+14},
    ["printPress"] = {"templates", 0, 24, 0+54, 24+14},
    ["undoPress"] = {"templates", 0, 1, 0+54, 1+14},
    ["S:toolTip"] = {"templates", 2, 99},
    ["S:colorStatics"] = {"color", 9, 62}, --0 84
    ["S:alphaNumber"] = {"color", 115, 16},-- 25 29
    ["S:colorDisplay"] = {"color", 14, 74, 43, 81}, --19 102 52 113
    ["S:miniBacking"] = {"color", 15, 50},
    ["backingLeft"] = {"color", 8, 50, 8+11, 50+10},
    ["backingRight"] = {"color", 40, 50, 40+11, 50+10},
    ["S:mainStatics"] = {"color", 9, 40},
    ["colorInput"] = {"color", 14, 74, 44, 82}, --6 96 +11 +23
    ["pickToggle"] = {"color", 9, 0, 9+18, 0+18}, --6 60 +23 +23
    ["fillToggle"] = {"color", 31, 0, 31+18, 0+18}, --30 60 +23 +23
    ["isWired"] = {"color", 9, 20, 9+18, 20+18},
    ["lightSelect"] = {"color", 31, 20, 31+18, 20+18},
    ["S:lightColor"] = {"color", 33, 22, 33+12, 22+12},
    ["S:spectrumWindow"] = {"colorWindow" , 0, 0},
    ["spectrumClose"] = {"colorWindow" , 174, 4, 174+21, 4+14},
    ["spectrumPress"] = {"colorWindow", 21, 25, 21+157, 25+55},
    ["S:errorWindow"] = {"errorWindow", 0, 0},
    ["S:errorPrompt1"] = {"errorWindow", 53, 91 },
    ["S:errorPrompt2"] = {"errorWindow", 56, 73}
  }
  --I tired to have some consistent button naming
  storage.buttonStates = storage.buttonStates or {frameAdd = "normal", frameDelete = "grayed", backingLeft = "normal", backingRight = "normal",
    frameLeft = "normal", frameRight = "normal", shiftRight = "normal", shiftLeft = "normal",
    shiftUp = "normal", shiftDown = "normal", clearPress = "normal", dumpPress = "normal", templateSlotScanButton = "normal",
    isWired = "off", printPress = "normal", iconGrab = "normal", undoPress = "grayed",
    colorInput = "normal", pickToggle = "off", fillToggle = "off",
    templateSlotCopy = "normal", lightSelect = "off"}
  --yes, paintColor contains the alpha, but since the user edits them independently this is useful
  storage.paintColor = storage.paintColor or "000000FF"
  storage.paintAlpha = storage.paintAlpha or 255

  --I hate some parts of lua. Using "pairs()" to copy tables is great, but I think it has issue when a table is indexed by both numbers
  --and strings. Hard to tell, but I'm pretty sure it keeps converting between the two. Very anoying since I have to use that function
  --to store and retrieve data.
  --
  --Well, after some changes it might not be necessary anymore, but that's why I've taken pains to index lightData buy "f#" instead of "#" everywhere.
  storage.frameTypesIndex = storage.frameTypesIndex or 1
  storage.backingTypesIndex = storage.backingTypesIndex or 1
  storage.isWired = storage.isWired or false
  self.currentCursorModifier = nil
  storage.currentPixelValueTo = storage.currentPixelValueTo or 1
  storage.currentIcon = storage.currentIcon or "customicons.png:blank-black"
  self.undoStack = {}
  self.lookingForSignDrop = 0
  dropSpot = world.entityPosition(pane.sourceEntity())

  --storage.buttonStates["undoPress"] = "grayed" storage.buttonStates["pickToggle"] = "off" storage.buttonStates["fillToggle"] = "off"

  local matchingCabinetList = world.objectQuery({world.entityPosition(pane.sourceEntity())[1]+7,world.entityPosition(pane.sourceEntity())[2]},1)
  for i,j in ipairs(matchingCabinetList) do
    if world.entityName(j) == "signdispenser" then self.matchingCabinet = j end
  end
  if self.matchingCabinet == nil then pane.dismiss() end
  --As a client-side script, I can't get returns from world.callScriptedEntity. I like to use this item drop method to get information from objects - here the sign in the input slot.
  -- (kyren) TODO: You can now get returns now as a JsonPromise, fix this up.
  requestSignDrop()
  --A bunch of transient states
  shiftHeld = false
  capsLock = false
  self.blinking = {false, 0}
  self.undoSubStack = {"reverseStroke"}
  self.toolTip = ""
  --Error format: {timer, "MessageLineOne", "MessageLineTwo"}
  self.thrownError = nil
  --Input format: {"Message", enteredSoFar, type}
  self.inputBoxMode = nil
  self.showSpectrumCursor = {0, {0,0}}
  self.clickplease = -1
  self.colorSelectBox = false

  --the object needs to know these things too, to persist through destruction
  world.sendEntityMessage(pane.sourceEntity(), "storeData", storage, templates)
end

function update(dt)
  self.canvas:clear()

  local toPointer = self.canvas:mousePosition()
  --keeps looking for a while for that sign drop
  if self.lookingForSignDrop > 0 then
    lookForTemplateSign()
  end
  --here click-and-drag is handled for the relevant actions
  --oldPointer updates, byt oldButton sticks with the intial click
  if storage.oldPointer ~= nil then
    if storage.oldButton == "pixelPress" then
      if detectButton(toPointer) == "pixelPress" then
        if (storage.oldPointer[1] ~= toPointer[1] or storage.oldPointer[2] ~= toPointer[2]) then
          setPixel(detectPixel(toPointer), storage.currentPixelValueTo)
        end
      end
    elseif storage.oldButton == "spectrumPress" then
      if detectButton(toPointer) == "spectrumPress" then
        setSpectrum(toPointer, 1)
      end
    end
    storage.oldPointer = toPointer
  end

  if self.clickplease == 0 then
    --executing button presses
    self.clickplease = -1
    if storage.oldPointer ~= nil and detectButton(storage.oldPointer) ~= nil then
      if storage.oldPointer ~= nil and storage.oldButton == detectButton(storage.oldPointer) then
        doButton(storage.oldButton, toPointer)
      elseif storage.oldButton == "pickPixel" and detectButton(storage.oldPointer) == "pixelPress" then
        doButton("pickPixel", toPointer)
      elseif storage.oldButton == "fillPixel" and detectButton(storage.oldPointer) == "pixelPress" then
        doButton("fillPixel", toPointer)
      end
    end
    --un-highlight buttons
    if storage.buttonStates[storage.oldButton] == "highlight" then
      storage.buttonStates[storage.oldButton] = "normal"
    end

    storage.oldPointer = nil
    storage.oldButton = nil
    --the undo sub-stack is specifically to handle multi-change "brush strokes"
    if #self.undoSubStack ~= 1 then
      pushToUndoStack(self.undoSubStack)
    end
    if storage.oldColor ~= nil then
      storage.paintColor = storage.oldColor
      storage.oldColor = nil
    end
    self.undoSubStack = {"reverseStroke"}
    updateButtonStates()
    --update the persistent storage
    world.setProperty(uniqueEaselIdentifier.."storage", tablecopy(storage))
    world.setProperty(uniqueEaselIdentifier.."templates", tablecopy(templates))
    world.sendEntityMessage(pane.sourceEntity(), "storeData", storage, templates)
  end
  if self.thrownError == nil and self.inputBoxMode == nil then
    updateToolTip(toPointer)
  end

  --update the sign's icon
  local wireString = ""
  local containerString = ""
  if storage.buttonStates["isWired"] == "on" then wireString = "-wired" end
  storage.currentIcon = "customicons.png:"..storage.backingTypes[storage.backingTypesIndex].."-"..storage.frameTypes[storage.frameTypesIndex][1]..wireString..containerString


  drawSignCanvas()
end

function updateToolTip(position)
  local blankTip = true
  local button = detectButton(position)
  if button ~= nil then
    --some tool-tips are state-dependent, so they're addressed individually here
    if string.len(button) > 11 and string.sub(button, 1, 12)  == "templateSlot" then
      self.toolTip = "Scan the sign in the input slot of the sign dispenser"
      blankTip = false
    elseif string.len(button) > 11 and string.sub(button, 1, 12) == "templateSave" then
      local templateIndex = "slot"..string.sub(button, -1)
      self.toolTip = "Save \""..storage.signName.."\" to Slot "..string.sub(templateIndex,-1)
      blankTip=false
    elseif button == "pixelPress" then
      if self.currentCursorModifier == "pickPixel" then
        self.toolTip = "[Left Click] to take color"
      elseif self.currentCursorModifier == "fillPixel" then
        self.toolTip = "[Left Click] to fill"
      else
        self.toolTip = "[Left Click] to draw, [Right Click] to erase"
      end
      blankTip = false
    elseif button == "undoPress" then
      if #self.undoStack > 0 then
        self.toolTip = "Undo previous actions ("..(undoTips[self.undoStack[#self.undoStack][1]] or "MISSING")..")"
        blankTip = false
      end
    else
      --most come from the array in customeasel-data.lua
      self.toolTip = toolTips[button] or "*MISSING TOOLTIP*"
      blankTip = false
    end
  end
  if blankTip then self.toolTip = "" end
end

function canvasClickEvent(position, button, isButtonDown)
  -- sb.logInfo("click event button %s is down? %s at position %s", button, isButtonDown, position)
  if self.thrownError == nil and self.inputBoxMode == nil then  --message boxes block input
    if isButtonDown and (button == 0 or button == 2) then     --middle mouse button isn't even a real mouse button man
      --sb.logInfo("Click @ %s", position)
      --some buttons need to start doing stuff on mouse down, so they start executing changes starts here
      if storage.oldPointer == nil then
        storage.oldPointer = position
        storage.oldButton = detectButton(storage.oldPointer)
        if storage.oldButton == "pixelPress" then
          if self.currentCursorModifier == nil then
            if button == 0 then --left click to draw
              storage.currentPixelValueTo = storage.paintColor
            elseif button == 2 then --right click to erase
              storage.currentPixelValueTo = 0
            end
            setPixel(detectPixel(storage.oldPointer), storage.currentPixelValueTo)
          else
            storage.oldButton = self.currentCursorModifier
          end
        elseif storage.oldButton == "spectrumPress" then
          storage.oldColor = storage.paintColor
          setSpectrum(position, 1)
        elseif storage.oldButton == "spectrumClose" then
          self.colorSelectBox = false
          self.showSpectrumCursor[1] = 0
        elseif storage.oldButton == nil or storage.buttonStates[storage.oldButton] == "grayed"  then
          storage.oldButton = nil
        else
          storage.buttonStates[storage.oldButton] = "highlight"
        end
      end
    elseif isButtonDown == false and (button == 0 or button == 2) then
      self.clickplease = 0
    end
  end
end

function canvasKeyEvent(key, isKeyDown)
  local keyString = nil
  --some ascii parsing mostly
  if 33<=key and key<=126 then keyString = string.char(key) else keyString = keyCodes[key] end
  if (shiftHeld or capsLock) and shiftHeld ~= capsLock then
    if 97<= key and key <=122 then
      keyString = string.char(key - 32)
    elseif keyCodes[key] ~= nil then
      keySring = keyCodes[key]
    else
      keyString = shiftKeyCodes[key]
    end
  else
    if 33<=key and key<=126 then
      keyString = string.char(key)
    else
      keyString = keyCodes[key]
    end
  end

  if isKeyDown then
    if keyString == "shift" then
      shiftHeld = true
    elseif keyString == "capslock" then
      if capsLock then capsLock = false else capsLock = true end
    end
  else
    if keyString == "shift" then
      shiftHeld = false
    end
    keyString = nil
  end

  if self.thrownError ~= nil then
    if keyString == "enter" then
      self.thrownError = nil
    end
    keyString = nil
  end

  if self.inputBoxMode ~= nil and keyString ~= nil then
    if keyString == "enter" then
      assignInputString(self.inputBoxMode[3], self.inputBoxMode[2])
      self.inputBoxMode = nil
    elseif keyString == "backspace" then
      if self.inputBoxMode[2] ~= "" then self.inputBoxMode[2] = string.sub(self.inputBoxMode[2], 1, -2) end
    elseif keyString == "space" and string.len(self.inputBoxMode[2]) < 30 then
      self.inputBoxMode[2] = self.inputBoxMode[2].." "
    elseif string.len(keyString) == 1 and string.len(self.inputBoxMode[2]) < 30 then
      self.inputBoxMode[2] = self.inputBoxMode[2]..keyString
    end
    keyString = nil
  end

  if self.colorSelectBox then
    if keyString == "enter" then
      self.colorSelectBox = false
      self.showSpectrumCursor[1] = 0
    end
    keyString = nil
  end
end


function drawSignCanvas()
  if storage.currentFrame > #storage.signPixels then storage.currentFrame = #storage.signPixels end

  --drawing all the bits, with relevant data dependencies
  ---------------
  --Main Anchor--
  ---------------
   self.canvas:drawImage("/interface/easel/staticpanels.png", buttonPosition("S:mainStatics"), 1)
   --self.canvas:drawImage("/interface/easel/icongrab.png:"..storage.buttonStates["iconGrab"],buttonPosition("iconGrab"), 1)
   self.canvas:drawImage("/interface/easel/signbacking.png:"..storage.backingTypes[storage.backingTypesIndex], buttonPosition("pixelPress"), 1.5)
   self.canvas:drawImage("/interface/easel/signframe.png:"..storage.frameTypes[storage.frameTypesIndex][1], buttonPosition("framePress"), 1.5)
   self.canvas:drawImage("/interface/easel/minisignbacking.png:"..storage.backingTypes[storage.backingTypesIndex], buttonPosition("S:miniBacking"), 1) --(20,6.5)
   self.canvas:drawImage("/interface/easel/scrollleft.png:"..storage.buttonStates["backingLeft"], buttonPosition("backingLeft"), 1)
   self.canvas:drawImage("/interface/easel/scrollright.png:"..storage.buttonStates["backingRight"], buttonPosition("backingRight"), 1)
   self.canvas:drawImage("/interface/easel/scrollleft.png:"..storage.buttonStates["frameLeft"], buttonPosition("frameLeft"), 1)
   self.canvas:drawImage("/interface/easel/scrollright.png:"..storage.buttonStates["frameRight"], buttonPosition("frameRight"), 1)
   self.canvas:drawImage("/interface/easel/delete.png:"..storage.buttonStates["frameDelete"], buttonPosition("frameDelete"), 1)
   self.canvas:drawImage("/interface/easel/add.png:"..storage.buttonStates["frameAdd"], buttonPosition("frameAdd"), 1)
   self.canvas:drawImage("/interface/easel/shiftleftright.png:right"..storage.buttonStates["shiftRight"], buttonPosition("shiftRight"), 1)
   self.canvas:drawImage("/interface/easel/shiftleftright.png:left"..storage.buttonStates["shiftLeft"], buttonPosition("shiftLeft"), 1)
   self.canvas:drawImage("/interface/easel/shiftupdown.png:up"..storage.buttonStates["shiftUp"], buttonPosition("shiftUp"), 1)
   self.canvas:drawImage("/interface/easel/shiftupdown.png:down"..storage.buttonStates["shiftDown"], buttonPosition("shiftDown"), 1)
   self.canvas:drawImage("/interface/easel/wiredicon.png:"..storage.buttonStates["isWired"], buttonPosition("isWired"), 1)

   if storage.lightData ~= nil then
     local lightDirective = "?replace=828282="..(storage.lightData or "808080")..";FFFFFF=" ..(storage.lightData or "808080")
     self.canvas:drawRect(button4Position("S:lightColor"), convertRGBAtoArray(storage.lightData))
     self.canvas:drawImage("/interface/easel/lightbutton.png:"..storage.buttonStates["lightSelect"], buttonPosition("lightSelect"), 1)
   else
    self.canvas:drawImage("/interface/easel/lightbutton.png:"..storage.buttonStates["lightSelect"], buttonPosition("lightSelect"), 1)
   end
   local digit12 = storage.currentFrame % 10
  local digit11 = (storage.currentFrame - digit12)/10
  local digit22 = #storage.signPixels % 10
  local digit21 = (#storage.signPixels - digit22)/10
  self.canvas:drawImage("/interface/easel/numbers.png:"..digit11,buttonPosition("S:digit11"), 1)
  self.canvas:drawImage("/interface/easel/numbers.png:"..digit12, buttonPosition("S:digit12"), 1)
  self.canvas:drawImage("/interface/easel/numbers.png:"..digit21,buttonPosition("S:digit21"), 1)
  self.canvas:drawImage("/interface/easel/numbers.png:"..digit22, buttonPosition("S:digit22"), 1) --(-1,3)
  for x=1,32 do
    for y=1,8 do
       if storage.signPixels[storage.currentFrame][x][y] ~= 0 then
        self.canvas:drawRect({
            buttonPosition("pixelPress")[1]-6+6*x,
            buttonPosition("pixelPress")[2]-6+6*y,
            buttonPosition("pixelPress")[1]+6*x,
            buttonPosition("pixelPress")[2]+6*y},
            convertRGBAtoArray(storage.signPixels[storage.currentFrame][x][y]))
       end
    end
  end
  -------------------
  --Template Anchor--
  -------------------
  self.canvas:drawImage("/interface/easel/new.png:"..storage.buttonStates["dumpPress"], buttonPosition("dumpPress"), 1) --(4,8)
  self.canvas:drawImage("/interface/easel/clear.png:"..storage.buttonStates["clearPress"], buttonPosition("clearPress"), 1) --(4,8)
  self.canvas:drawImage("/interface/easel/print.png:"..storage.buttonStates["printPress"], buttonPosition("printPress"), 1) --(8,8)
  self.canvas:drawImage("/interface/easel/undo.png:"..storage.buttonStates["undoPress"], buttonPosition("undoPress"), 1) --(12,8)

  self.canvas:drawImage("/interface/easel/scaninput.png:"..storage.buttonStates["templateSlotScanButton"], buttonPosition("templateSlotScanButton"), 1)
  self.canvas:drawImage("/interface/easel/iconthing.png", buttonPosition("templateSlotCopy"), 1)
  if templates["fromContainer"] ~= nil then
    self.canvas:drawImage("/objects/outpost/customsign/"..templates["fromContainer"].currentIcon, vec2.add(buttonPosition("templateSlotCopy"), {1,0}), 1)
  end
  if storage.buttonStates["templateSlotCopy"] == "highlight" then
    self.canvas:drawRect(button4Position("templateSlotCopy"), {255,255,255,70}) end

  self.canvas:drawText(self.toolTip, {position=buttonPosition("S:toolTip")}, 8, {210,210,210,210})

  ----------------
  --Color Anchor--
  ----------------
   self.canvas:drawImage("/interface/easel/staticcolor.png", buttonPosition("S:colorStatics"), 1) --(12,8)
   self.canvas:drawImage("/interface/easel/pickericon.png:"..storage.buttonStates["pickToggle"], buttonPosition("pickToggle"), 1) --(19.5,3)
   self.canvas:drawImage("/interface/easel/fillicon.png:"..storage.buttonStates["fillToggle"], buttonPosition("fillToggle"), 1) --(21,3)
   self.canvas:drawRect(button4Position("S:colorDisplay"),convertRGBAtoArray(storage.paintColor))


  ----------------
  --Popup Anchors--
  ----------------
  if self.thrownError ~= nil then
    self.canvas:drawImage("/interface/easel/errorpane.png", buttonPosition("S:errorWindow"), 1)
    self.canvas:drawText(self.thrownError[2], {position=buttonPosition("S:errorPrompt1")},20,{220,0,0,255})
    self.canvas:drawText(self.thrownError[3], {position=buttonPosition("S:errorPrompt2")},20,{220,0,0,255})
    if self.thrownError[1] == 1 then self.thrownError = nil else self.thrownError[1] = self.thrownError[1] - 1 end
  end

  if self.colorSelectBox then
    self.canvas:drawImage("/interface/easel/spectrumchart_window.png", buttonPosition("S:spectrumWindow"), 1)
    self.canvas:drawImage("/interface/easel/spectrumchart.png", buttonPosition("spectrumPress"), 1)
  end

  if self.showSpectrumCursor[1] > 0 then
    self.canvas:drawImage("/interface/easel/spectrumcursor.png", self.showSpectrumCursor[2], 1)
    self.showSpectrumCursor[1] = self.showSpectrumCursor[1]-1
  end
end

-------------------
--Button Fuctions--
-------------------

function detectButton(mousepos)
  --the color selection box should override all. since one button works, the intercept goes here rather than in canvasClickEvent
  if self.colorSelectBox then
    pixelEntry = canvasButtonOffsets["spectrumPress"]
    if (canvasAnchors[pixelEntry[1]][1]+pixelEntry[2] <= mousepos[1]) and (mousepos[1] <= canvasAnchors[pixelEntry[1]][1]+pixelEntry[4]) and (canvasAnchors[pixelEntry[1]][2]+pixelEntry[3] <= mousepos[2]) and (mousepos[2] <= canvasAnchors[pixelEntry[1]][2]+pixelEntry[5]) then
      return "spectrumPress"
    end
    pixelEntry = canvasButtonOffsets["spectrumClose"]
    if (canvasAnchors[pixelEntry[1]][1]+pixelEntry[2] <= mousepos[1]) and (mousepos[1] <= canvasAnchors[pixelEntry[1]][1]+pixelEntry[4]) and (canvasAnchors[pixelEntry[1]][2]+pixelEntry[3] <= mousepos[2]) and (mousepos[2] <= canvasAnchors[pixelEntry[1]][2]+pixelEntry[5]) then
      return "spectrumClose"
    end
    return nil
  end

  --and since pixelPress overrides framePress, but pairs() process it later, it gets a special pass
  local pixelEntry = canvasButtonOffsets["pixelPress"]
  if (canvasAnchors[pixelEntry[1]][1]+pixelEntry[2] <= mousepos[1]) and (mousepos[1] <= canvasAnchors[pixelEntry[1]][1]+pixelEntry[4]) and (canvasAnchors[pixelEntry[1]][2]+pixelEntry[3] <= mousepos[2]) and (mousepos[2] <= canvasAnchors[pixelEntry[1]][2]+pixelEntry[5]) then
    return "pixelPress"
  end

  --same with shiftLeft
  local pixelEntry = canvasButtonOffsets["shiftLeft"]
  if (canvasAnchors[pixelEntry[1]][1]+pixelEntry[2] <= mousepos[1]) and (mousepos[1] <= canvasAnchors[pixelEntry[1]][1]+pixelEntry[4]) and (canvasAnchors[pixelEntry[1]][2]+pixelEntry[3] <= mousepos[2]) and (mousepos[2] <= canvasAnchors[pixelEntry[1]][2]+pixelEntry[5]) then
    return "shiftLeft"
  end

  --and shiftRight
  local pixelEntry = canvasButtonOffsets["shiftRight"]
  if (canvasAnchors[pixelEntry[1]][1]+pixelEntry[2] <= mousepos[1]) and (mousepos[1] <= canvasAnchors[pixelEntry[1]][1]+pixelEntry[4]) and (canvasAnchors[pixelEntry[1]][2]+pixelEntry[3] <= mousepos[2]) and (mousepos[2] <= canvasAnchors[pixelEntry[1]][2]+pixelEntry[5]) then
    return "shiftRight"
  end

  --and shiftUp
  local pixelEntry = canvasButtonOffsets["shiftUp"]
  if (canvasAnchors[pixelEntry[1]][1]+pixelEntry[2] <= mousepos[1]) and (mousepos[1] <= canvasAnchors[pixelEntry[1]][1]+pixelEntry[4]) and (canvasAnchors[pixelEntry[1]][2]+pixelEntry[3] <= mousepos[2]) and (mousepos[2] <= canvasAnchors[pixelEntry[1]][2]+pixelEntry[5]) then
    return "shiftUp"
  end

  --and shiftDown
  local pixelEntry = canvasButtonOffsets["shiftDown"]
  if (canvasAnchors[pixelEntry[1]][1]+pixelEntry[2] <= mousepos[1]) and (mousepos[1] <= canvasAnchors[pixelEntry[1]][1]+pixelEntry[4]) and (canvasAnchors[pixelEntry[1]][2]+pixelEntry[3] <= mousepos[2]) and (mousepos[2] <= canvasAnchors[pixelEntry[1]][2]+pixelEntry[5]) then
    return "shiftDown"
  end

  for button, entry in pairs(canvasButtonOffsets) do
    if string.sub(button, 1, 2) ~= "S:" and (canvasAnchors[entry[1]][1]+entry[2] <= mousepos[1]) and (mousepos[1] <= canvasAnchors[entry[1]][1]+entry[4]) and (canvasAnchors[entry[1]][2]+entry[3] <= mousepos[2]) and (mousepos[2] <= canvasAnchors[entry[1]][2]+entry[5]) then
      if button ~= "spectrumPress" and button ~= "spectrumClose" then
        return button
      end
    end
  end
  return nil
end

function doButton(button, position)
  --sb.logInfo("Button: %s", button)
  if button == "framePress" then --just cycles the frame index
    pushToUndoStack({"framePress", storage.frameTypesIndex})
    if storage.frameTypesIndex < #storage.frameTypes then
      storage.frameTypesIndex = storage.frameTypesIndex + 1
    else
      storage.frameTypesIndex = 1
    end
  elseif button == "backingRight" then --just shifts the backingindex
    pushToUndoStack({"backingPress", storage.backingTypesIndex})
    if storage.backingTypesIndex < #storage.backingTypes then
      storage.backingTypesIndex = storage.backingTypesIndex + 1
    else
      storage.backingTypesIndex = 1
    end
  elseif button == "backingLeft" then --just shifts the backing index
    pushToUndoStack({"backingPress", storage.backingTypesIndex})
    if storage.backingTypesIndex == 1 then
      storage.backingTypesIndex = #storage.backingTypes
    else
      storage.backingTypesIndex = storage.backingTypesIndex - 1
    end
  elseif button == "frameRight" then --just chooses the current frame. I hate having two "frames" be relevant in this context. could have picked better terms at the start
    if storage.currentFrame == #storage.signPixels then
      storage.currentFrame = 1
    else
      storage.currentFrame = storage.currentFrame + 1
    end
  elseif button == "frameLeft" then --just chooses the current frame
    if storage.currentFrame == 1 then
      storage.currentFrame = #storage.signPixels
    else
      storage.currentFrame = storage.currentFrame - 1
    end
  elseif button == "shiftRight" then --moves all the pixels on the frame at once
    pushToUndoStack({"restoreFrame", storage.currentFrame, storage.signPixels[storage.currentFrame]})
    storage.signPixels[storage.currentFrame] = pixelShift(1, 0)
  elseif button == "shiftLeft" then  --moves all the pixels on the frame at once
    pushToUndoStack({"restoreFrame", storage.currentFrame, storage.signPixels[storage.currentFrame]})
    storage.signPixels[storage.currentFrame] = pixelShift(-1, 0)
  elseif button == "shiftUp" then  --moves all the pixels on the frame at once
    pushToUndoStack({"restoreFrame", storage.currentFrame, storage.signPixels[storage.currentFrame]})
    storage.signPixels[storage.currentFrame] = pixelShift(0, 1)
  elseif button == "shiftDown" then  --moves all the pixels on the frame at once
    pushToUndoStack({"restoreFrame", storage.currentFrame, storage.signPixels[storage.currentFrame]})
    storage.signPixels[storage.currentFrame] = pixelShift(0, -1)
  elseif button == "clearPress" then --removes all pixels from the current frame
    pushToUndoStack({"restoreFrame", storage.currentFrame, storage.signPixels[storage.currentFrame]})
    for x=1,32 do
      for y=1,8 do
        storage.signPixels[storage.currentFrame][x][y] = 0
      end
    end
  elseif button == "isWired" then --toggles "wired" state
    if storage.isWired then
      storage.isWired = false
    else
      storage.isWired = true
    end
  elseif button == "dumpPress" then --reduces sign to one, empty frame
    pushToUndoStack({"restoreSignPixels", storage.signPixels, storage.lightData})
    storage.currentFrame = 1
    storage.signPixels = {{}}
    for x=1,32 do
       storage.signPixels[storage.currentFrame][x] = {}
      for y=1,8 do
         storage.signPixels[storage.currentFrame][x][y] = 0
      end
    end
    storage.buttonStates["frameDelete"] = "grayed"
  elseif button == "frameAdd" then --copies the current frame to the end of the animation
    pushToUndoStack({"removeFrame", #storage.signPixels + 1})
    storage.signPixels[#storage.signPixels + 1] = tablecopy(storage.signPixels[storage.currentFrame])
    storage.currentFrame = #storage.signPixels
  elseif button == "printPress" then --make me a sign!
    outputSign()
  elseif button == "frameDelete" then --removes current frame
    pushToUndoStack({"insertFrame", storage.currentFrame, storage.signPixels[storage.currentFrame]})
    table.remove(storage.signPixels, storage.currentFrame)
    if storage.currentFrame ~= 1 then
      storage.currentFrame = storage.currentFrame - 1
    end
  elseif button == "iconGrab" then --totally deprecated, as this is automatic now.
    pushToUndoStack({"restoreIcon", storage.currentIcon})
    local wireString = ""
    local containerString = ""
    if storage.buttonStates["isWired"] == "on" then wireString = "-wired" end
    storage.currentIcon = "customicons.png:"..storage.backingTypes[storage.backingTypesIndex].."-"..storage.frameTypes[storage.frameTypesIndex][1]..wireString..containerString
  elseif button == "undoPress" and #self.undoStack > 0 then --the undo button has to do, well, pretty much all that the other buttons do. just in reverse.
    local action = self.undoStack[#self.undoStack]
    --sb.logInfo("Undoing %s", action)
    if action[1] == "framePress" then
      storage.frameTypesIndex = action[2]
    elseif action[1] == "backingPress" then
      storage.backingTypesIndex = action[2]
    elseif action[1] == "restoreFrame" then
      storage.signPixels[action[2]] = tablecopy(action[3])
    elseif action[1] == "restoreSignPixels" then
      storage.signPixels = tablecopy(action[2])
      storage.lightData = tablecopy(action[3])
      storage.currentFrame = #storage.signPixels
    elseif action[1] == "removeFrame" then
      if storage.currentFrame >= action[2] then storage.currentFrame = storage.currentFrame - 1 end
    table.remove(storage.signPixels, storage.currentFrame)
      table.remove(storage.signPixels,action[2])
    elseif action[1] == "insertFrame" then
      table.insert(storage.signPixels,action[2],tablecopy(action[3]))
      storage.currentFrame = action[2]
    elseif action[1] == "restoreIcon" then
      storage.currentIcon = action[2]
    elseif action[1] == "reverseStroke" then
      storage.currentFrame = action[2][3]
      for i=2,#action do
        setPixel(action[i][1], action[i][2], action[i][3])
      end
    elseif action[1] == "restoreColor" then
      storage.paintColor = action[2]
      storage.paintAlpha = convertRGBAtoArray(action[2])[4]
      self.showSpectrumCursor = {0, action[3]}
    elseif action[1] == "restoreFromTemplate" then
      storage.signPixels = action[2]
      storage.frameTypesIndex = action[3]
      storage.backingTypesIndex = action[4]
      storage.isWired = action[5]
      storage.currentIcon = action[6]
      storage.signName = action[7]
      storage.currentFrame = action[8]
      storage.lightData = action[9]
    elseif action[1] == "lightChange" then
      storage.lightData = action[2]
    end
    table.remove(self.undoStack)
  elseif button == "spectrumPress" then --unlike painting, changing the color with the spectrum selector only "locks in" if mouseup is over it
    pushToUndoStack({"restoreColor", storage.oldColor, position})
    storage.oldColor = nil
    setSpectrum(position, 30)
  elseif button == "pickToggle" then
    if self.currentCursorModifier == "pickPixel" then self.currentCursorModifier = nil else self.currentCursorModifier = "pickPixel" end
  elseif button == "fillToggle" then
    if self.currentCursorModifier == "fillPixel" then self.currentCursorModifier = nil else self.currentCursorModifier = "fillPixel" end
  elseif button == "pickPixel" then --since the paintbrush modifiers work by calling on virtual buttons, here that stuff executes
    local selectPix = detectPixel(position)
    local selectColor = storage.signPixels[storage.currentFrame][selectPix[1]][selectPix[2]]
    if selectColor ~= 0 then
      pushToUndoStack({"restoreColor", storage.paintColor, position})
      storage.paintColor = selectColor
      self.currentCursorModifier = nil
    end
  elseif button == "fillPixel" then
    pushToUndoStack({"restoreFrame", storage.currentFrame, storage.signPixels[storage.currentFrame]})
    recursiveFiller(detectPixel(position))
  elseif string.len(button) > 11 and string.sub(button, 1, 12)  == "templateSlot" then --which template to load from? it's in the button name
    local templateIndex = string.sub(button, 13)
    if string.len(templateIndex) == 1 then
      templateIndex = "slot"..templateIndex
    else
      templateIndex = "fromContainer"
    end
    pushToUndoStack({"restoreFromTemplate", storage.signPixels, storage.frameTypesIndex, storage.backingTypesIndex, storage.isWired, storage.currentIcon, storage.signName, storage.currentFrame, storage.lightData})
    if templates[templateIndex] ~= nil then --old signs might be missing some properties
      storage.signPixels = tablecopy(templates[templateIndex].signPixels)
      storage.frameTypesIndex = templates[templateIndex].frameTypesIndex or 1
      storage.backingTypesIndex = templates[templateIndex].backingTypesIndex or 1
      storage.isWired = templates[templateIndex].isWired or false
      storage.currentIcon = templates[templateIndex].currentIcon or "customicons.png:blank-black"
      storage.signName = templates[templateIndex].signName or "Sign"
      storage.lightData = tablecopy(templates[templateIndex].lightData)
      if storage.currentFrame > #storage.signPixels then storage.currentFrame = #storage.signPixels end
    end
  elseif string.len(button) > 11 and string.sub(button, 1, 12) == "templateSave" then
    local templateIndex = "slot"..tostring(string.sub(button, -1))
    templates[templateIndex] = {}
    templates[templateIndex].signPixels = tablecopy(storage.signPixels)
    templates[templateIndex].frameTypesIndex = storage.frameTypesIndex
    templates[templateIndex].backingTypesIndex = storage.backingTypesIndex
    templates[templateIndex].isWired = storage.isWired
    templates[templateIndex].currentIcon = storage.currentIcon
    templates[templateIndex].signName = storage.signName
    templates[templateIndex].lightData = tablecopy(storage.lightData)
  elseif button == "colorInput" then --these buttons enable window states - make no changes themseleves, but change how the interface takes input
    --self.inputBoxMode = {"Input RGB (format: \"r.g.b\")","","color"}
    self.colorSelectBox = true
  elseif button == "lightSelect" then
    -- Not using per frame lighting anymore
    -- pushToUndoStack({"lightChange", storage.currentFrame, storage.lightData["f"..tostring(storage.currentFrame)]})
    -- if storage.lightData["f"..tostring(storage.currentFrame)] == string.sub(storage.paintColor, 1, -3) then
    --   storage.lightData["f"..tostring(storage.currentFrame)] = nil
    -- else
    --   storage.lightData["f"..tostring(storage.currentFrame)] = string.sub(storage.paintColor, 1, -3)
    -- end
    pushToUndoStack({"lightChange", storage.lightData})
    if storage.lightData == string.sub(storage.paintColor, 1, -3) then
      storage.lightData = nil
    else
      storage.lightData = string.sub(storage.paintColor, 1, -3)
    end
  end
end

function detectPixel(mousepos)
  --for finding where you are on the main body of the sign
  local returnPixel = nil
  local pixBounds = {canvasAnchors[canvasButtonOffsets["pixelPress"][1]][1]+canvasButtonOffsets["pixelPress"][2],
  canvasAnchors[canvasButtonOffsets["pixelPress"][1]][2]+canvasButtonOffsets["pixelPress"][3],
  canvasAnchors[canvasButtonOffsets["pixelPress"][1]][1]+canvasButtonOffsets["pixelPress"][4],
  canvasAnchors[canvasButtonOffsets["pixelPress"][1]][2]+canvasButtonOffsets["pixelPress"][5]
  }
  if (pixBounds[1] <= mousepos[1]) and (mousepos[1] <= pixBounds[3]) and (pixBounds[2] <= mousepos[2]) and (mousepos[2] <= pixBounds[4]) then
    returnPixel = {}
    returnPixel[1] = math.floor(1+(mousepos[1]-pixBounds[1])/6)
    returnPixel[2] = math.floor(1+(mousepos[2]-pixBounds[2])/6)
  end
  return returnPixel
end

function setPixel(pixel, value, forceFrame)
  --this function used to have to do more, so it looks messy for what little it does
  if (0 < pixel[1]) and (pixel[1] < 33) and (0 < pixel[2]) and (pixel[2] < 9) then
    if type(forceFrame) ~= "number" then
      if value ~= storage.signPixels[storage.currentFrame][pixel[1]][pixel[2]] then
        --undo substack to keep track of a full stroke
        table.insert(self.undoSubStack, {pixel, storage.signPixels[storage.currentFrame][pixel[1]][pixel[2]], storage.currentFrame})
        storage.signPixels[storage.currentFrame][pixel[1]][pixel[2]] = value
      end
    else
      storage.signPixels[forceFrame][pixel[1]][pixel[2]] = value
    end
  end
end

function pushToUndoStack(newAction)
  table.insert(self.undoStack, tablecopy(newAction))
  storage.buttonStates["undoPress"] = "normal"
  if #self.undoStack > 50 then
    table.remove(self.undoStack, 1)
  end
end

function pixelShift(h, v)
  --returns a shifted version of the current frame
  --would like to have the bleed stored somehow, but seemed hard to do nicely
  local tempFrame = {}
  for x=1,32 do
    tempFrame[x] = {}
    for y=1,8 do
       tempFrame[x][y] = 0
    end
  end
  for x=1,32 do
    for y=1,8 do
      if (x==1 and h == 1) or (x==32 and h==-1) or (y==1 and v==1) or (y==8 and v==-1) then
        tempFrame[x][y] = 0
      else
        tempFrame[x][y] = storage.signPixels[storage.currentFrame][x - h][y - v]
      end
    end
  end
  return tempFrame
end

function assignInputString(stringType, input)
  --the relevant string parsing for inputs
  local isInvalid = false
  if stringType == "name" then
    if input ~= "" then storage.signName = input end
  elseif stringType == "alpha" then
    if tonumber(input) ~= nil and 0 <= tonumber(input) and tonumber(input) < 256 then
      pushToUndoStack({"restoreColor", storage.paintColor})
      storage.paintAlpha = tonumber(input)
      local rgba = convertRGBAtoArray(storage.paintColor)
      storage.paintColor = convertArraytoRGBA({rgba[1], rgba[2], rgba[3]})
    else
      isInvalid = true
    end
  --the color input is defunct now I suppose
  elseif stringType == "color" then
    --mmm patterns I should use more of those
    if input == string.match(input, "%d+[.]%d+[.]%d+") then
      local r, g, b = string.match(input, "(%d+)[.](%d+)[.](%d+)")
      r = tonumber(r) g = tonumber(g) b = tonumber(b)
      if 0 <= r and r < 256 and 0 <= g and g < 256 and 0 <= b and b < 256 then
        pushToUndoStack({"restoreColor", storage.paintColor})
        storage.paintColor = convertArraytoRGBA({r,g,b})
      else
        isInvalid = true
      end
    else
      isInvalid = true
    end
  end
  if isInvalid then
    self.thrownError = {300, "ERROR! INVALID ARGUMENT", "OBEY GIVEN CRITERIA"}
  end
end

---------------------------
--Sign Handling Functions--
---------------------------

function requestSignDrop(args)
  world.sendEntityMessage(pane.sourceEntity(), "requestSignDrop", dropSpot)
  self.lookingForSignDrop = 25
end

function lookForTemplateSign()
  --scans around the drop point for a sign drop
  self.droppedSign = world.getProperty("SignStoreDrop")
  if self.droppedSign ~= nil then
    self.lookingForSignDrop = 0
    templates["fromContainer"] = {}
    --sb.logInfo("Dropped sign: %s", data.droppedSign)
    templates["fromContainer"].signPixels = deconstructDirectiveStrings(self.droppedSign["signData"])
    templates["fromContainer"].frameTypesIndex = self.droppedSign["frameColors"]
    for p,q in ipairs(storage.frameTypes) do
    if templates["fromContainer"].frameTypesIndex[1] == q[2] and templates["fromContainer"].frameTypesIndex[2] == q[3] then
      templates["fromContainer"].frameTypesIndex = p break
    end
    end
    templates["fromContainer"].backingTypesIndex = self.droppedSign["signBacking"]
    for p,q in ipairs(storage.backingTypes) do
      if templates["fromContainer"].backingTypesIndex == q then templates["fromContainer"].backingTypesIndex = p break end
    end
    if self.droppedSign["isWired"] then
      templates["fromContainer"].isWired = true
    else
      templates["fromContainer"].isWired = false
    end
    templates["fromContainer"].currentIcon = self.droppedSign["inventoryIcon"]
    templates["fromContainer"].signName = self.droppedSign["signName"]
    templates["fromContainer"].lightData = self.droppedSign["signLight"]
    world.setProperty("SignStoreDrop", nil)
  else
    self.lookingForSignDrop = self.lookingForSignDrop - 1
  end
end

function deconstructDirectiveStrings(directiveStrings)
  --strings have format: replace=rrggbbaa=rrggbbaa;rrggbbaa=rrggbbaa;etc.
  local temporaryPixels = {{}}
  local pix = 1 local piy = 1
  for i=1,#directiveStrings do
    temporaryPixels[i] = {}
    for x=1,32 do
      temporaryPixels[i][x] = {}
      for y=1,8 do
        temporaryPixels[i][x][y] = 0
      end
    end
    if directiveStrings[i] ~= nil and directiveStrings[i] ~= "" then
      --I should use string.match here, but I wrote it before I found that function and it works so...
      p = 9
      while (p + 16 <= #directiveStrings[i]) do
        pix = tonumber(string.sub(directiveStrings[i], p, p+1))
        piy = tonumber(string.sub(directiveStrings[i], p+4, p+5))
        --sb.logInfo("Frame %s, Pixel %s,%s", i, pix, piy)
        temporaryPixels[i][pix][piy] = string.sub(directiveStrings[i], p+9, p+16)
        p = p + 18
      end
    end
  end
  return temporaryPixels
end

function outputSign()
  --sb.logInfo("//////////Printing Sign//////////")
  convertToDirectiveString()

  local parameters = {}
  local itemName = ""
  itemName = storage.isWired and "wiredcustomsign" or "customsign"
  parameters.signData = storage.signDirectiveStrings
  parameters.inventoryIcon = storage.currentIcon
  parameters.signBacking = storage.backingTypes[storage.backingTypesIndex]
  parameters.frameColors = {storage.frameTypes[storage.frameTypesIndex][2], storage.frameTypes[storage.frameTypesIndex][3]}
  parameters.isWired = storage.isWired
  parameters.signLight = storage.lightData
  parameters.animationParts = {["background"] = storage.backingTypes[storage.backingTypesIndex]}
  parameters.signName = storage.signName
  --sb.logInfo("Wired: %s - Container: %s - Backing: %s - Frame: %s", storage.isWired, storage.isContainer, storage.backingTypes[storage.backingTypesIndex], storage.frameTypes[storage.frameTypesIndex][2])
  --sb.logInfo("%s", storage.signDirectiveStrings")
  local signToPlace = {}
  local signInSlot = nil
  local placementSlot = false
  signToPlace.name = itemName
  signToPlace.count = 1
  signToPlace.parameters = parameters
  --sb.logInfo("Sign To Place: %s", signToPlace)

  --Can't use the world.container_ commands directly, they don't work properly from this context
  local fitSpots = world.containerItemsFitWhere(self.matchingCabinet, signToPlace).slots
  table.sort(fitSpots)

  local outputSuccess = false
  if #fitSpots > 0 and fitSpots[1] ~= 8 then
    world.sendEntityMessage(pane.sourceEntity(), "putInChest", signToPlace, fitSpots[1])
    outputSuccess = true
  else
    for i = 0, 7 do
      if not world.containerItemAt(self.matchingCabinet, i) then
        world.sendEntityMessage(pane.sourceEntity(), "putInChest", signToPlace, i)
        outputSuccess = true
        break
      end
    end
  end

  if not outputSuccess then
    self.thrownError = {500, "   ERROR! NANO-PAPER JAM", "     PLEASE CLEAR OUTPUT"}
  end
  --sb.logInfo("---------------------------------")
end

function convertToDirectiveString()
  storage.signDirectiveStrings = {}
  local subDirective = "replace="
  local oldDirective = ""
  local needSemicolon = false
  for i=1,#storage.signPixels do
    subDirective = "replace="
    needSemicolon = false
    --in the sign, x and y are indexed with r and b, respectively
    for x=1,32 do
      for y=1,8 do
        if storage.signPixels[i][x][y] ~= 0 then
          if needSemicolon then subDirective = subDirective..";" else needSemicolon = true end
          if x<10 then
            subDirective = subDirective .. "0" .. x .. "000" .. y .. "01=" .. storage.signPixels[i][x][y]
          else
            subDirective = subDirective .. x .. "000" .. y .. "01=" .. storage.signPixels[i][x][y]
          end
        end
      end
    end
    --entries with no pixels are ""
    if subDirective == "replace=" then subDirective = "" end
    storage.signDirectiveStrings[i] = subDirective
  end
end

---------------------
--Utility Fucntions--
---------------------
function buttonPosition(button)
  if canvasButtonOffsets[button] == nil then sb.logInfo("%s", button) end
  return {canvasAnchors[canvasButtonOffsets[button][1]][1]+canvasButtonOffsets[button][2], canvasAnchors[canvasButtonOffsets[button][1]][2]+canvasButtonOffsets[button][3]}
end

function button4Position(button)
  return {canvasAnchors[canvasButtonOffsets[button][1]][1]+canvasButtonOffsets[button][2], canvasAnchors[canvasButtonOffsets[button][1]][2]+canvasButtonOffsets[button][3],
      canvasAnchors[canvasButtonOffsets[button][1]][1]+canvasButtonOffsets[button][4]+1, canvasAnchors[canvasButtonOffsets[button][1]][2]+canvasButtonOffsets[button][5]+1}
end

function tablecopy(input)
  --stupid lua and its stupid table pointers
  --i keep forgetting it works that way, no end of grief
  if input == nil then return nil end
  if type(input) ~= "table" then
    local newinput = input
    return newinput
  end
  local newtab = {}
  for i,j in pairs(input) do
    newtab[i] = tablecopy(j)
  end
  return newtab
end


function recursiveFiller(p, oc)
  --not the most sophisticated of fill tools, but it does a decent job
  --sb.logInfo("Filling at position %s: %s to %s", p, storage.paintColor, oc)
  if 1<=p[1] and p[1]<=32 and 1<=p[2] and p[2]<=8 then
    local testColor = storage.signPixels[storage.currentFrame][p[1]][p[2]]
    if testColor ~= storage.paintColor and (oc == nil or testColor == oc) then
      storage.signPixels[storage.currentFrame][p[1]][p[2]] = storage.paintColor
      recursiveFiller({p[1]-1,p[2]}, testColor)
      recursiveFiller({p[1]+1,p[2]}, testColor)
      recursiveFiller({p[1],p[2]-1}, testColor)
      recursiveFiller({p[1],p[2]+1}, testColor)
    end
  end
end

function updateButtonStates()
  --except when theyre highlighted, the state dependence of all buttons is handled here
  if #storage.signPixels == 1 then
    storage.buttonStates["frameDelete"] = "grayed"
  else
    storage.buttonStates["frameDelete"] = "normal"
  end

  if #storage.signPixels >= 99 then
    storage.buttonStates["frameAdd"] = "grayed"
  else
    storage.buttonStates["frameAdd"] = "normal"
  end

  if storage.isWired then
    storage.buttonStates["isWired"] = "on"
  else
    storage.buttonStates["isWired"] = "off"
  end

  if self.currentCursorModifier == "pickPixel" then
    storage.buttonStates["pickToggle"] = "on"
  else
    storage.buttonStates["pickToggle"] = "off"
  end

  if self.currentCursorModifier == "fillPixel" then
    storage.buttonStates["fillToggle"] = "on"
  else
    storage.buttonStates["fillToggle"] = "off"
  end

  if #self.undoStack == 0 then
    storage.buttonStates["undoPress"] = "grayed"
  else
    storage.buttonStates["undoPress"] = "normal"
  end

  if storage.lightData ~= nil then
    storage.buttonStates["lightSelect"] = "on"
  else
    storage.buttonStates["lightSelect"] = "off"
  end
end

function setSpectrum(pos, duration)
  --yes, it just checks against a pre-loaded array of the sub-image's pixel values
  --at least bmp data is pretty simple to grab
  local spectrumPos = button4Position("spectrumPress")
  local spectrumIndex = {pos[1]-spectrumPos[1]+1, spectrumPos[4]-pos[2]+1}
  if spectrumRGBTable[spectrumIndex[1]][spectrumIndex[2]] ~= nil then
    storage.paintColor = convertArraytoRGBA(spectrumRGBTable[spectrumIndex[1]][spectrumIndex[2]])
    self.showSpectrumCursor = {duration, {pos[1]-2, pos[2]-2}}
  end
end
--["color"] = {80,80}
--3 32 +53 +11

function convertArraytoRGBA(RGB)
  --definitely should have done that dual-use function with these, would be nice, elegant
  local RGBA = ""
  if RGB[1] < 16 then RGBA = RGBA.."0"..string.format("%x", RGB[1]) else RGBA = RGBA..string.format("%x", RGB[1]) end
  if RGB[2] < 16 then RGBA = RGBA.."0"..string.format("%x", RGB[2]) else RGBA = RGBA..string.format("%x", RGB[2]) end
  if RGB[3] < 16 then RGBA = RGBA.."0"..string.format("%x", RGB[3]) else RGBA = RGBA..string.format("%x", RGB[3]) end
  if storage.paintAlpha < 16 then RGBA = RGBA.."0"..string.format("%x", storage.paintAlpha) else RGBA = RGBA..string.format("%x", storage.paintAlpha) end
  return RGBA
end

function convertRGBAtoArray(rgba)
  return {tonumber(string.sub(rgba,1,2),16),
  tonumber(string.sub(rgba,3,4),16),
  tonumber(string.sub(rgba,5,6),16),
  tonumber(string.sub(rgba,7,8),16)}
end

function table.tostring( tbl )
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert( result, table.val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end

function table.val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table.tostring( v ) or
      tostring( v )
  end
end

function table.key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. table.val_to_str( k ) .. "]"
  end
end
