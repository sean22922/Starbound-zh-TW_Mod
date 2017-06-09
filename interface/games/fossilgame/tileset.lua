require "/interface/games/util.lua"

TileLayer = {}
function TileLayer:new(size, tileSize)
  local newSet = {
    position = {0,0},
    color = {255, 255, 255},
    seed = math.random(1,999999),
    size = size,
    tileSize = tileSize,
    tiles = {},
    onTileAdded = Event:new(),
    onTileRemoved = Event:new(),
    tileDamage = {}
  }
  for i = 1, size[1] * size[2] do
    table.insert(newSet.tiles, 0)
  end
  setmetatable(newSet, extend(self))
  return newSet
end

function TileLayer:setMaterialData(material)
  self.materialPath=material.texturePath
  self.materialVariants=material.variants
end

function TileLayer:fill(value)
  for i = 1, self.size[1] * self.size[2] do
    self.tiles[i] = value
  end
end

function TileLayer:index(position)
  local zeroIndex = (position[2] * self.size[1]) + position[1]
  return zeroIndex + 1
end

function TileLayer:tile(tilePosition)
  return self.tiles[self:index(tilePosition)]
end

function TileLayer:setTile(tilePosition, value)
  local tile = self.tiles[self:index(tilePosition)]
  if tile ~= value then
    if value then
      self.onTileAdded:trigger(tilePosition)
    else
      self.onTileRemoved:trigger(tilePosition)
    end
  end
  self.tiles[self:index(tilePosition)] = value
end

function TileLayer:damageTile(tilePosition)
  self.tileDamage[self:index(tilePosition)] = true
end

function TileLayer:tilePosition(screenPosition)
  local x = math.floor((screenPosition[1] - self.position[1]) / self.tileSize)
  local y = math.floor((screenPosition[2] - self.position[2]) / self.tileSize)

  if x < 0 or y < 0 then return false end
  if x >= self.size[1] or y >= self.size[2] then return false end

  return {x, y}
end

function TileLayer:tile(tilePosition)
  if tilePosition[1] < 0 or tilePosition[1] >= self.size[1] or tilePosition[2] < 0 or tilePosition[2] >= self.size[2] then
    return false
  else
    return self.tiles[self:index(tilePosition)]
  end
end

function TileLayer:draw()
  math.randomseed(self.seed)

  for i,value in ipairs(self.tiles) do
    i = i - 1 -- Lua is 1-indexed but we want to start at 0
    local x = i % self.size[1]
    local y = (i - x) / self.size[1]
    local r=math.random()
    if value then
      self:drawTile(x, y, r, self.tileDamage[i+1])
    end
  end
end

function TileLayer:drawTile(x, y, r, damaged)
  local screenX = x * self.tileSize + self.position[1]
  local screenY = y * self.tileSize + self.position[2]
  local quad = {screenX, screenY, screenX + self.tileSize, screenY + self.tileSize}

  local variant = math.floor(r * self.materialVariants)
  local scale = self.tileSize / 8

  local yOff = root.imageSize(self.materialPath)[2] - 24 -- color y offset
  local texCoords = {4 + (16 * variant), yOff + 4, 12 + (16 * variant), yOff + 12}
  gameCanvas:drawImageRect(self.materialPath, texCoords, quad, self.color)
  if damaged then
    gameCanvas:drawImageRect("/tiles/blockdamage.png", {32,0,40,8}, quad, {255,255,255,150})
  end

  local right = self:tile({x + 1, y})
  local top = self:tile({x, y + 1})
  local left = self:tile({x - 1, y})
  local bottom = self:tile({x, y - 1})
  local topright = self:tile({x + 1, y + 1})
  local topleft = self:tile({x - 1, y + 1})
  local bottomleft = self:tile({x - 1, y - 1})
  local bottomright = self:tile({x + 1, y - 1})

  if not top then
    if not topright and not topleft then
      gameCanvas:drawImageRect(self.materialPath, {texCoords[1], texCoords[4], texCoords[3], texCoords[4] + 4}, {quad[1], quad[4], quad[3], quad[4] + 4*scale}, self.color) --edge
    elseif not topright then
      gameCanvas:drawImageRect(self.materialPath, {texCoords[1] - 4, yOff + 16, texCoords[1], yOff + 20}, {quad[1], quad[4], quad[3] - 4*scale, quad[4] + 4*scale}, self.color) --corner
      gameCanvas:drawImageRect(self.materialPath, {texCoords[1] + 4, texCoords[4], texCoords[3], texCoords[4] + 4}, {quad[1] + 4*scale, quad[4], quad[3], quad[4] + 4*scale}, self.color) --edge
    elseif not topleft then
      gameCanvas:drawImageRect(self.materialPath, {texCoords[1], yOff + 16, texCoords[1] + 4, yOff + 20}, {quad[1] + 4*scale, quad[4], quad[3], quad[4] + 4*scale}, self.color) --corner
      gameCanvas:drawImageRect(self.materialPath, {texCoords[1], texCoords[4], texCoords[3] - 4, texCoords[4] + 4}, {quad[1], quad[4], quad[3] - 4*scale, quad[4] + 4*scale}, self.color) --edge
    else
      gameCanvas:drawImageRect(self.materialPath, {texCoords[1] - 4, yOff + 16, texCoords[1] + 4, yOff + 20}, {quad[1], quad[4], quad[3], quad[4] + 4*scale}, self.color) --corner
    end
  end

  if not bottom then
    if not bottomright and not bottomleft then
      gameCanvas:drawImageRect(self.materialPath, {texCoords[1], texCoords[2] - 4, texCoords[3], texCoords[2]}, {quad[1], quad[2] - 4*scale, quad[3], quad[2]}, self.color)
    elseif not bottomright then
      gameCanvas:drawImageRect(self.materialPath, {texCoords[1] - 4, yOff + 20, texCoords[1], yOff + 24}, {quad[1], quad[2] - 4*scale, quad[3] - 4*scale, quad[2]}, self.color) -- corner
      gameCanvas:drawImageRect(self.materialPath, {texCoords[1] + 4, texCoords[2] - 4, texCoords[3], texCoords[2]}, {quad[1] + 4*scale, quad[2] - 4*scale, quad[3], quad[2]}, self.color) -- edge
    elseif not bottomleft then
      gameCanvas:drawImageRect(self.materialPath, {texCoords[1], yOff + 20, texCoords[1] + 4, yOff + 24}, {quad[1] + 4*scale, quad[2] - 4*scale, quad[3], quad[2]}, self.color) -- corner
      gameCanvas:drawImageRect(self.materialPath, {texCoords[1], texCoords[2] - 4, texCoords[3] - 4, texCoords[2]}, {quad[1], quad[2] - 4*scale, quad[3] - 4*scale, quad[2]}, self.color) -- edge
    else
      gameCanvas:drawImageRect(self.materialPath, {texCoords[1] - 4, yOff + 20, texCoords[1] + 4, yOff + 24}, {quad[1], quad[2] - 4*scale, quad[3], quad[2]}, self.color) -- corner
    end
  end

  if not right then
    if not bottomright and not topright then
      gameCanvas:drawImageRect(self.materialPath, {texCoords[3], texCoords[2], texCoords[3] + 4, texCoords[4]}, {quad[3], quad[2], quad[3] + 4*scale, quad[4]}, self.color)
    elseif not topright then
      gameCanvas:drawImageRect(self.materialPath, {texCoords[3], texCoords[2] + 4, texCoords[3] + 4, texCoords[4]}, {quad[3], quad[2] + 4*scale, quad[3] + 4*scale, quad[4]}, self.color)
    elseif not bottomright then
      gameCanvas:drawImageRect(self.materialPath, {texCoords[3], texCoords[2], texCoords[3] + 4, texCoords[4] - 4}, {quad[3], quad[2], quad[3] + 4*scale, quad[4] - 4*scale}, self.color)
    end
  end

  if not left then
    if not bottomleft and not topleft then
      gameCanvas:drawImageRect(self.materialPath, {texCoords[1] - 4, texCoords[2], texCoords[1], texCoords[4]}, {quad[1] - 4*scale, quad[2], quad[1], quad[4]}, self.color)
    elseif not topleft then
      gameCanvas:drawImageRect(self.materialPath, {texCoords[1] - 4, texCoords[2] + 4, texCoords[1], texCoords[4]}, {quad[1] - 4*scale, quad[2] + 4*scale, quad[1], quad[4]}, self.color)
    elseif not bottomleft then
      gameCanvas:drawImageRect(self.materialPath, {texCoords[1] - 4, texCoords[2], texCoords[1], texCoords[4] - 4}, {quad[1] - 4*scale, quad[2], quad[1], quad[4] - 4*scale}, self.color)
    end
  end
end
