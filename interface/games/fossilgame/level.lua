require "/scripts/vec2.lua"
require "/interface/games/util.lua"
require "/interface/games/fossilgame/tileset.lua"
require "/interface/games/fossilgame/fossil.lua"

Level = {}

function Level:new(size, tileSize, position, dirt, rock, bone)
  local newLevel = {
    tileSize = tileSize,
    size = size,
    position = position,
    dirtMaterial = dirt,
    rockMaterial = rock,
    boneMaterial = bone,
    treasureMaterial = treasure,

    rockLayer = TileLayer:new(size, tileSize),
    dirtLayer = TileLayer:new(vec2.add(size, 2), tileSize),
    boneLayer = TileLayer:new(size, tileSize),
    background = TileLayer:new(vec2.add(size, 2), tileSize),

    fossilDamaged=false,
    hasTreasure=false,
    treasurePos={},
    treasureDamaged=false,

    particles = {}
  }
  setmetatable(newLevel, extend(self))
  return newLevel
end

function Level:init()
  self.background:setMaterialData(self.dirtMaterial)
  self.background:fill(true)
  self.background.color = {100, 100, 100}
  self.background.position = vec2.sub(self.position, self.tileSize)

  self.dirtLayer:setMaterialData(self.dirtMaterial)
  self.dirtLayer:fill(true)
  self.dirtLayer.position = vec2.sub(self.position, self.tileSize)

  self.rockLayer:setMaterialData(self.rockMaterial)
  self.rockLayer:fill(false)
  self.rockLayer.position = self.position

  self.boneLayer:setMaterialData(self.boneMaterial)
  self.boneLayer:fill(false)
  self.boneLayer.position = self.position

  self.fossilTiles = {}
  self.boneLayer.onTileAdded:register(function(tilePos)
    table.insert(self.fossilTiles, tilePos)
  end)

  self.treasureTiles = {}

  self.progress = 0
  self.dirtLayer.onTileRemoved:register(function(tilePos)
    tilePos = vec2.sub(tilePos, 1)
    if self:fossilAt(tilePos) then
      self.progress = self.progress + 1
    end
    self:spawnDirtParticles(tilePos)
  end)
  self.rockLayer.onTileRemoved:register(function(tilePos)
    self:spawnRockParticles(tilePos)
  end)
end

function Level:update(dt)
  self:updateParticles(dt)
end

function Level:draw()
  self.background:draw()
  self.boneLayer:draw()

  if self.hasTreasure then
    self:drawTreasure()
  end

  self.dirtLayer:draw()
  self.rockLayer:draw()
end

function Level:fossilCoveredByRock()
  for _,tilePos in pairs(self.fossilTiles) do
    if self.rockLayer:tile(tilePos) then
      return true
    end
  end
  return false
end

function Level:fossilUncovered()
  return self.progress >= #self.fossilTiles
end

function Level:rockAt(tilePosition)
  return self.rockLayer:tile(tilePosition)
end

function Level:removeRock(tilePosition)
  self.rockLayer:setTile(tilePosition, false)
end

function Level:addRock(tilePosition)
  self.rockLayer:setTile(tilePosition, true)
end

function Level:dirtAt(tilePosition)
  tilePosition = vec2.add(tilePosition, 1)
  return self.dirtLayer:tile(tilePosition)
end

function Level:removeDirt(tilePosition)
  tilePosition = vec2.add(tilePosition, 1)
  self.dirtLayer:setTile(tilePosition, false)
end

function Level:addDirt(tilePosition)
  tilePosition = vec2.add(tilePosition, 1)
  self.dirtLayer:setTile(tilePosition, true)
end

function Level:fossilAt(tilePosition)
  for _,tile in ipairs(self.fossilTiles) do
    if tile[1] == tilePosition[1] and tile[2] == tilePosition[2] then
      return true
    end
  end
  return false
end

function Level:removeFossil()
  for i,tile in pairs(self.fossilTiles) do
    self.boneLayer:setTile(tile, false)
    self:spawnBoneParticles(tile)
  end
  pane.playSound(config.getParameter("fossilDamageSound"), 0, 1.0)
  self.progress = 0
  self.fossilTiles = {}
end


function Level:addBone(tilePosition)
  self.boneLayer:setTile(tilePosition, true)
end

function Level:damageFossil()
  if not self.fossilDamaged then
    for i,tile in pairs(self.fossilTiles) do
      self.boneLayer:damageTile(tile)
      if not self:rockAt(tile) and not self:dirtAt(tile) then
        self:spawnBoneParticles(tile)
      end
    end
    pane.playSound(config.getParameter("fossilDamageSound"), 0, 1.0)
  end

  self.fossilDamaged = true
end

-- Treasure

function Level:treasureAt(tilePos)
  return contains(self.treasureTiles, tilePos)
end

function Level:setTreasure(treasure, position)
  self.hasTreasure = true
  self.treasurePos = position
  self.treasure = treasure

  for x = 0, treasure.size[1]-1 do
    for y = 0, treasure.size[2]-1 do
      table.insert(self.treasureTiles, {position[1] + x, position[2] + y})
    end
  end
end

function Level:treasureUncovered()
  if not self.hasTreasure then return false end

  for _,tilePos in pairs(self.treasureTiles) do
    if self:dirtAt(tilePos) or self:rockAt(tilePos) then
      return false
    end
  end
  return true
end

function Level:treasureCoveredByRock()
  if not self.hasTreasure then return false end

  for _,tilePos in pairs(self.treasureTiles) do
    if self:rockAt(tilePos) then
      return true
    end
  end
  return false
end

function Level:drawTreasure()
  local screenX = self.treasurePos[1] * self.tileSize + self.position[1]
  local screenY = self.treasurePos[2] * self.tileSize + self.position[2]
  gameCanvas:drawImage(self.treasure.image, {screenX, screenY}, 2)
end

function Level:removeTreasure()
  if not self.hasTreasure then return end

  self.hasTreasure = false
  for _,tilePos in pairs(self.treasureTiles) do
    for i = 1, 25 do
      local colorFade = math.random()
      local color = {100 + colorFade * 20, 50 + colorFade * 20, 0, 255}
      self:spawnTileParticle(tilePos, self.tileSize, color)
    end
  end
end

function Level:tilePosition(screenPosition)
  local tile =  {
    math.floor((screenPosition[1] - self.position[1]) / self.tileSize),
    math.floor((screenPosition[2] - self.position[2]) / self.tileSize)
  }
  if tile[1] < 0 or tile[1] >= self.size[1] or tile[2] < 0 or tile[2] >= self.size[2] then
    return false
  else
    return tile
  end
end

function Level:screenPosition(tilePosition)
  return {
    tilePosition[1] * self.tileSize + self.position[1],
    tilePosition[2] * self.tileSize + self.position[2]
  }
end

-- Particles

function Level:updateParticles(dt)
  local kept = {}
  for k,particle in pairs(self.particles) do
    particle.age = particle.age + dt
    if particle.age <= particle.ttl then
      table.insert(kept, particle)
    end
  end
  self.particles = kept
end

function Level:drawParticles()
  for _,particle in pairs(self.particles) do
    local opacity = math.min((1 - particle.age / particle.ttl) * 4, 1) * particle.color[4]
    local color = {particle.color[1], particle.color[2], particle.color[3], opacity}
    local position = vec2.add(particle.position, vec2.mul(particle.velocity, particle.age))

    local quad = translateRect({-particle.size / 2, -particle.size / 2, particle.size / 2, particle.size / 2}, position)
    gameCanvas:drawRect(quad, color)
  end
end

function Level:spawnParticle(position, velocity, color, size, ttl)
  table.insert(self.particles, {
    position = position,
    velocity = velocity,
    color = color,
    size = size,
    ttl = ttl,
    age = 0
  })
end

function Level:spawnTileParticle(tilePosition, tileSize, color)
  local screen = self:screenPosition(tilePosition)
  local position = { math.random(screen[1], screen[1] + tileSize), math.random(screen[2], screen[2] + tileSize) }
  local velocity = {math.random(-20, 20), math.random(-20, 20)}
  local size = math.random(1,4)
  local ttl = 0.25 + math.random() * 0.5
  self:spawnParticle(position, velocity, color, size, ttl)
end

function Level:spawnDirtParticles(tilePosition)
  for i = 1, 20 do
    local colorFade = math.random()
    local color = {153 + colorFade * 66, 89 + colorFade * 100, 0 + colorFade * 100, 150}
    self:spawnTileParticle(tilePosition, self.tileSize, color)
  end
end

function Level:spawnRockParticles(tilePosition)
  for i = 1, 20 do
    local colorFade = math.random()
    local color = {50 + colorFade * 100, 50 + colorFade * 100, 50 + colorFade * 100, 255}
    self:spawnTileParticle(tilePosition, self.tileSize, color)
  end
end

function Level:spawnBoneParticles(tilePosition)
  for i = 1, 10 do
    local colorFade = math.random() * 55
    local color = {200 + colorFade, 200 + colorFade, 170 + colorFade, 255}
    self:spawnTileParticle(tilePosition, self.tileSize, color)
  end
end
