UIElement = {}
UIElement.position = {0,0}
UIElement.size = {0,0}

function UIElement:new()
  local newElement = {}
  setmetatable(newElement, extend(self))
  return newElement
end

function UIElement:handleClick(event)
  local position = vec2.sub(event.position, self.position)

  if pointInRect({0,0,self.size[1],self.size[2]}, position) and event.button == 0 then
    return self:onClick(event), self
  end
  return true, self
end

function UIElement:onClick(event)
  return true
end

-----------------------------------------------------------

RadioButtonSet = UIElement:new()
function RadioButtonSet:new()
  local newSet = {
    buttons = {}
  }
  setmetatable(newSet, extend(self))
  return newSet
end

function RadioButtonSet:add(toggleButton, data)
  --Override toggle functionality
  toggleButton.onClick = function(btn,event)
    self:select(toggleButton)
    return false
  end

  if self.selected == nil then
    self:select(toggleButton)
  end
  table.insert(self.buttons, toggleButton)
end

function RadioButtonSet:select(selected)
  for i,button in pairs(self.buttons) do
    button.state = false
  end
  selected.state = true
  self.selected = selected
end

function RadioButtonSet:data()
  return self.selected.data
end

function RadioButtonSet:selectIndex(index)
  if #self.buttons >= index then
    self:select(self.buttons[index])
  end
end

function RadioButtonSet:handleClick(event)
  local propagate = false
  for i,button in pairs(self.buttons) do
    propagate = button:handleClick(event)
    if not propagate then
      self:select(button)
      return propagate, button
    end
  end
  return propagate, self
end

function RadioButtonSet:draw()
  for _,button in pairs(self.buttons) do
    button:draw()
  end
end

-----------------------------------------------------------

ToggleButton = UIElement:new()
ToggleButton.state = false
ToggleButton.background = Sprite:new("/interface/games/fossilgame/images/button.png", {20,20}, {2,1}, 2)
ToggleButton.size = {20,20}

function ToggleButton:new(iconImage, backgroundImage, position, data)
  local iconSize = root.imageSize(iconImage)
  local backgroundSize = root.imageSize(backgroundImage)
  backgroundSize[1] = backgroundSize[1] / 2

  local newButton = {
    position = position,
    icon = Sprite:new(iconImage, iconSize, {1,1}, 1),
    background = Sprite:new(backgroundImage, backgroundSize, {2,1}, 2), --two frames, left and right used for toggle state
    size = backgroundSize,
    data = data
  }
  setmetatable(newButton, extend(self))
  return newButton
end

function ToggleButton:onClick(clickEvent)
  self.state = not self.state
  return false
end

function ToggleButton:draw()
  self.background:setCell(self.state and 1 or 0)
  self.background:draw(self.position)
  --icon centered in button.
  self.icon:draw(vec2.add(self.position, {(self.background.size[1] - self.icon.size[1]) / 2, (self.background.size[2] - self.icon.size[2]) / 2}))
end