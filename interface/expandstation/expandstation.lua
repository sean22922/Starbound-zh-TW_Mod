require "/scripts/vec2.lua"
require "/scripts/rect.lua"
require "/scripts/poly.lua"
require "/scripts/util.lua"
require "/objects/playerstation/stationgrid.lua"

function init()
  self.partConfig = root.assetJson("/dungeons/space/playerstation/parts.config")

  self.itemList = "partListArea.scrollArea.itemList"
  self.canvas = widget.bindCanvas("previewCanvas")

  self.filled = false
  self.listItems = {}

  self.promises = {}

  self.selectedPart = nil

  self.blockedTimer = 0

  updateGrid()
end

function update(dt)
  for i,promise in pairs(self.promises) do
    if promise.promise:finished() then
      if promise.promise:succeeded() then
        promise.callback(promise.promise:result())
      end
      self.promises[i] = nil
    end
  end

  drawPreview()
  updateItemList()

  if self.anchor and self.grid and self.selectedPart then
    local part = self.partConfig.parts[self.selectedPart]
    if partPlaceable(part) and partCraftable(part) then
      widget.setButtonEnabled("placeButton", true)
    else
      widget.setButtonEnabled("placeButton", false)
    end
  end

  if self.blockedTimer > 0 then
    self.blockedTimer = math.max(self.blockedTimer - script.updateDt(), 0.0)
    if self.blockedTimer > 0 then
      widget.setText("warning", config.getParameter("warningMessages.blocked"))
    else
      itemSelected()
    end
  end
end

function partPlaceable(part)
  if self.anchor and self.grid then
    local offset = anchoredPartOffset(part, self.anchor.direction)
    if offset and partAllowedAt(self.grid, part, vec2.add(self.anchor.position, offset)) then
      return true
    end
  end
  return false
end

function partCraftable(part)
  if player.isAdmin() then return true end
  for _,input in pairs(part.input) do
    if player.hasCountOfItem(input[1]) < input[2] then
      return false
    end
  end
  return true
end

function createTooltip(mousePosition)
  local part = nil
  for n,w in pairs(self.listItems) do
    if widget.inMember(w, mousePosition) then
      part = self.partConfig.parts[n]
      break
    end
  end
  if part == nil then
    return
  end

  local inputs = part.input
  local tooltip = config.getParameter("tooltipLayout")
  local itemList = config.getParameter("itemList")
  local itemTemplate = config.getParameter("listTemplate")
  local startPos = itemList.position
  local memberSize = itemList.memberSize
  local spacing = itemList.spacing

  local listHeight = #inputs * (memberSize[2] + spacing[2]) - spacing[2]
  tooltip.background.size[2] = tooltip.background.size[2] + listHeight

  local offset = 200 - tooltip.background.size[2]
  startPos[2] = startPos[2] + offset
  tooltip.background.position[2] = tooltip.background.position[2] + offset
  tooltip.title.position[2] = tooltip.title.position[2] + listHeight + offset
  for i = #inputs, 1, -1 do
    local input = inputs[i]
    local itemName, count = input[1], input[2]
    local itemConfig = root.itemConfig(itemName)

    local newItem = {
      type = "layout",
      layoutType = "basic",
      rect = {startPos[1], startPos[2], startPos[1] + memberSize[1], startPos[2]+memberSize[2]},
      zlevel = 10,
      children = {}
    }
    newItem.children.background = copy(itemTemplate.background)
    newItem.children.itemName = copy(itemTemplate.itemName)
    newItem.children.itemName.value = itemConfig.config.shortdescription

    newItem.children.itemIcon = copy(itemTemplate.itemIcon)
    newItem.children.itemIcon.file = util.absolutePath(itemConfig.directory, itemConfig.config.inventoryIcon)

    local hasCount = player.hasCountOfItem(itemName)
    newItem.children.count = copy(itemTemplate.count)
    newItem.children.count.value = hasCount.."/"..count
    if hasCount >= count then
      newItem.children.count.color = "green"
    else
      newItem.children.count.color = "red"
    end

    startPos[2] = startPos[2] + memberSize[2] + spacing[2]

    tooltip["item"..i] = newItem
  end

  return tooltip
end

function updateGrid()
  table.insert(self.promises, {
    promise = world.sendEntityMessage(pane.sourceEntity(), "getGrid"),
    callback = function(result)
      self.grid = result.grid
      self.anchor = result.anchor
      updateGrid()
    end
  })
end

function itemSelected(...)
  self.blockedTimer = 0
  local selected = widget.getListSelected(self.itemList)
  self.selectedPart = widget.getData(self.itemList.."."..selected)

  local part = self.partConfig.parts[self.selectedPart]
  widget.setImage("selectedIcon", part.icon)
  widget.setText("selectedName", part.displayName)
  widget.setText("selectedDescription", part.description)

  widget.setButtonEnabled("placeButton", false)
  if self.grid and self.anchor then
    local offset = anchoredPartOffset(part, self.anchor.direction)
    if offset then
      local allowed, reason = partAllowedAt(self.grid, part, vec2.add(self.anchor.position, offset or {0, 0}))
      local craftable = partCraftable(part)
      if allowed and craftable then
        widget.setButtonEnabled("placeButton", true)
        widget.setText("warning", "")
      elseif not allowed then
        if reason[1] == "range" then
          widget.setText("warning", config.getParameter("warningMessages.range"))
        elseif reason[1] == "overlap" then
          widget.setText("warning", config.getParameter("warningMessages.overlap"))
        elseif reason[1] == "invalid" then
          widget.setText("warning", config.getParameter("warningMessages.invalid"))
        elseif reason[1] == "blocking" then
          widget.setText("warning", config.getParameter("warningMessages.blocking"))
        end
      elseif not craftable then
        widget.setText("warning", config.getParameter("warningMessages.uncraftable"))
      end
    else
      widget.setText("warning", config.getParameter("warningMessages.unplaceable"))
    end
  end
end

function placePart()
  if self.grid and self.anchor and self.selectedPart then
    local part = self.partConfig.parts[self.selectedPart]
    local offset = anchoredPartOffset(part, self.anchor.direction)
    if partPlaceable(part) and partCraftable(part) then
      local partName = self.selectedPart
      local tilePos = vec2.add(self.anchor.position, offset)
      table.insert(self.promises, {
        promise = world.sendEntityMessage(pane.sourceEntity(), "lockPart", partName, tilePos),
        callback = function(res, reason)
          if res[1] then
            local consumed = {}
            for _,input in pairs(part.input) do
              if player.isAdmin() or player.consumeItem({name = input[1], count = input[2]}) then
                table.insert(consumed, input)
              else
                -- if consuming any items fails for some magical reason, return the consumed ones
                for _,ret in pairs(consumed) do
                  player.giveItem({name = ret[1], count = ret[2]})
                end
                return
              end
            end

            table.insert(self.promises, {
              promise = world.sendEntityMessage(pane.sourceEntity(), "placePart", partName, tilePos),
              callback = function(res)
                if res == false then
                  -- if placement failed, return the items
                  -- this is very very unlikely to happen
                  for _,ret in pairs(consumed) do
                    player.giveItem({name = ret[1], count = ret[2]})
                  end
                end
              end
            })
          elseif res[2] == "blocked" then
            pane.playSound(config.getParameter("errorSound"))
            self.blockedTimer = 2.0
          end
        end
      })
    end
  end
end

function fillItemList()
  widget.clearListItems(self.itemList)

  local parts = util.keys(self.partConfig.parts)
  table.sort(parts, function(a, b)
    local aPlace = partPlaceable(self.partConfig.parts[a])
    local bPlace = partPlaceable(self.partConfig.parts[b])
    if aPlace == bPlace then
      return a < b
    end

    return aPlace
  end)

  for _,partName in pairs(parts) do
    local part = self.partConfig.parts[partName]
    if part.placeable then
      local item = string.format("%s.%s", self.itemList, widget.addListItem(self.itemList))
      widget.setData(item, partName)

      widget.setText(item..".itemName", part.displayName)
      widget.setImage(item..".itemIcon", part.icon)

      self.listItems[partName] = item
    end
  end
end

-- used to update craftable status, doesn't refill the list
function updateItemList()
  if self.grid and self.anchor and not self.filled then
    fillItemList()
    self.filled = true
  end

  for n,w in pairs(self.listItems) do
    local part = self.partConfig.parts[n]
    if partPlaceable(part) and partCraftable(part) then
      widget.setVisible(w..".notcraftableoverlay", false)
    else
      widget.setVisible(w..".notcraftableoverlay", true)
    end
  end
end

function drawPreview()
  self.canvas:clear()

  if self.grid and self.anchor then
    local dimensions = {8, 8}
    local canvasSize = widget.getSize("previewCanvas")
    local tileSize = {
      canvasSize[1] / dimensions[1],
      canvasSize[1] / dimensions[2]
    }

    local center = vec2.add(self.anchor.position, {0.5, 0.5})
    center = vec2.add(center, vec2.mul(self.anchor.direction, -1))
    local screenPos = vec2.sub(vec2.mul(center, tileSize), vec2.div(widget.getSize("previewCanvas"), 2))

    local minX = math.floor(center[1] - dimensions[1] / 2)
    local maxX = math.ceil(center[1] + dimensions[1] / 2)
    local minY = math.max(0, math.floor(center[2] - dimensions[2] / 2))
    local maxY = math.min(self.grid.size[2], math.ceil(center[2] + dimensions[2] / 2))
    for x = minX, maxX do
      for y = minY, maxY do
        local border = {
          {0, 0},
          {0, tileSize[2]},
          {tileSize[1], tileSize[2]},
          {tileSize[1], 0}
        }
        border = poly.translate(border, vec2.sub(vec2.mul({x, y}, tileSize), screenPos))
        self.canvas:drawPoly(border, "gray")

        -- if something is placed in that tile, fill the grid in
        if not tileAvailable(self.grid, {x, y}) then
          local quad = rect.pad(rect.scale({0, 0, 1, 1}, tileSize), {-1, -1})
          local pos = vec2.sub(vec2.mul({x, y}, tileSize), screenPos)
          self.canvas:drawRect(rect.translate(quad, pos), {200, 200, 200})
        end
      end
    end

    for x = minX, maxX do
      for y = minY, maxY do
        if not tileAvailable(self.grid, {x, y}) then
          for _,anchor in pairs(tileAnchors(self.grid, {x, y})) do
            local pos = vec2.sub(vec2.mul({x, y}, tileSize), screenPos)
            local line = poly.translate(poly.scale(anchorLine(anchor), tileSize), pos)
            self.canvas:drawLine(line[1], line[2], "white", 2)
          end
        end
      end
    end

    local currentAnchorColor = "yellow"
    if self.selectedPart then
      local part = self.partConfig.parts[self.selectedPart]
      local partOffset = anchoredPartOffset(part, self.anchor.direction)

      local placeableColor = "green"
      local anchorColor = "blue"
      local overlapColor = "red"
      local blockedTileColor = "orange"
      local blockedAnchorColor = "red"

      local placeable = true
      if partOffset == nil then
        partOffset = {0, 0}
        placeableColor = "red"
        currentAnchorColor = "red"
        placeable = false
      end

      for _,tile in pairs(part.tiles) do
        local pos = vec2.add(vec2.add(tile, partOffset), self.anchor.position)
        local quad = rect.pad(rect.scale({0, 0, 1, 1}, tileSize), {-1, -1})
        self.canvas:drawRect(rect.translate(quad, vec2.sub(vec2.mul(pos, tileSize), screenPos)), placeableColor)
      end

      for _,a in pairs(part.anchors) do
        local dir, anchorOffset = a[1], a[2]
        if not compare(vec2.mul(dir, -1), self.anchor.direction) then
          local line = anchorLine(dir)
          line = {
            vec2.add(vec2.add(vec2.add(line[1], anchorOffset), partOffset), self.anchor.position),
            vec2.add(vec2.add(vec2.add(line[2], anchorOffset), partOffset), self.anchor.position)
          }
          self.canvas:drawLine(vec2.sub(vec2.mul(line[1], tileSize), screenPos), vec2.sub(vec2.mul(line[2], tileSize), screenPos), anchorColor, 2)
        end
      end

      if placeable then
        local allowed, reason = partAllowedAt(self.grid, part, vec2.add(self.anchor.position, partOffset))
        if not allowed then
          if reason[1] == "overlap" or reason[1] == "range" then
            -- draw overlap in red
            local pos = reason[2]
            local quad = rect.pad(rect.scale({0, 0, 1, 1}, tileSize), {-1, -1})
            self.canvas:drawRect(rect.translate(quad, vec2.sub(vec2.mul(pos, tileSize), screenPos)), overlapColor)
          elseif reason[1] == "invalid" or reason[1] == "blocking" then
            -- draw invalid anchor in red
            local tile, dir = reason[2], reason[3]
            local line = poly.translate(anchorLine(dir), tile)
            self.canvas:drawLine(vec2.sub(vec2.mul(line[1], tileSize), screenPos), vec2.sub(vec2.mul(line[2], tileSize), screenPos), blockedAnchorColor, 2)
            local quad = rect.pad(rect.scale({0, 0, 1, 1}, tileSize), {-1, -1})
            self.canvas:drawRect(rect.translate(quad, vec2.sub(vec2.mul(tile, tileSize), screenPos)), blockedTileColor)
          end
        end
      end
    end

    local line = poly.translate(anchorLine(self.anchor.direction), vec2.add(self.anchor.position, vec2.mul(self.anchor.direction, -1)))
    self.canvas:drawLine(vec2.sub(vec2.mul(line[1], tileSize), screenPos), vec2.sub(vec2.mul(line[2], tileSize), screenPos), currentAnchorColor, 2)
  end
end

function anchorLine(direction)
  if direction[1] > 0 then
    return {{1.0, 0.2}, {1.0, 0.8}}
  elseif direction[1] < 0 then
    return {{0.0, 0.2}, {0.0, 0.8}}
  elseif direction[2] > 0 then
    return {{0.2, 1.0}, {0.8, 1.0}}
  elseif direction[2] < 0 then
    return {{0.2, 0.0}, {0.8, 0.0}}
  end
end
