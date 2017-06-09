require "/interface/games/util.lua"
require "/interface/games/fossilgame/level.lua"

LevelGenerator = {}

function LevelGenerator:new(tools)
  local newGenerator = {
    tools = tools,
    toolRockChance = 0.5,
    randomRockChance = 0.5
  }
  setmetatable(newGenerator, extend(self))
  return newGenerator
end

function LevelGenerator:generate(size, tileSize, position, dirt, rock, bone, treasure)
  local level, toolUses
  repeat
    toolUses = false
    level = Level:new(size, tileSize, position, dirt, rock, bone, treasure)
    level:init()

    self.fossilTiles = level.fossilTiles

    self:placeFossil(level)

    if self:placeTreasure(level, treasure) then
      self.treasureTiles = level.treasureTiles

      toolUses = self:placeRocks(level)
    end
  until toolUses

  return level, toolUses
end

function LevelGenerator:placeRocks(level)
  local min = 0
  local max = level.size[2]

  -- Generate a solution and place rocks where tools should be used
  local toolUses = {}
  for i = 1, math.random(6, 8) do
    table.insert(toolUses, self.tools[math.random(1,#self.tools)])
  end

  local used = {}
  local toolTiles = {}
  local placed = false
  for _,tool in ipairs(toolUses) do
    toolTiles, placed = self:placeToolAdjacent(level, toolTiles, self.fossilTiles, {}, tool)
    if placed then
      used[tool.name] = (used[tool.name] or 0) + 1
    end
  end
  for _,tile in pairs(toolTiles) do
    if not level:treasureAt(tile) and (level:fossilAt(tile) or math.random() <= self.toolRockChance) then
      level:addRock(tile)
    end
  end

  if #self.treasureTiles > 0 then
    local treasureTool = self.tools[math.random(1,#self.tools)]
    local treasureTiles, placed = self:placeToolAdjacent(level, {}, self.treasureTiles, self.fossilTiles, treasureTool)
    if placed then
      for _,tile in pairs(treasureTiles) do
        if level:treasureAt(tile) or math.random() <= self.toolRockChance then
          level:addRock(tile)
        end
      end
    else
      return false
    end
  end

  -- Place some meaningless rocks all over the place
  for x = 0, level.size[1] - 1 do
    for y = 0, level.size[2] - 1 do
      if math.random() <= self.randomRockChance
        and not level:treasureAt({x,y})
        and not level:fossilAt({x,y})
        and not contains(toolTiles, {x,y}) then
          level:addRock({x,y})
      end
    end
  end
  return used
end

function LevelGenerator:placeFossil(level)
  local fossilType = FossilTypes[math.random(1,#FossilTypes)]
  local fossil = Fossil:new(fossilType)

  for i = 0, math.random(0, 3) do
    fossil:rotate()
  end
  local offset = {math.random(0, level.size[1] - fossil.size[1]), math.random(0, level.size[2] - fossil.size[2])}
  fossil:place(level, offset)
end

function LevelGenerator:placeTreasure(level, treasure)
  if treasure.size[1] == 0 or treasure.size[1] == 0 then
    return true
  end

  local treasureOptions={}
  local canPlace = function(position)
    for x=0, treasure.size[1]-1 do
      for y=0, treasure.size[2]-1 do
        if level:fossilAt({position[1] + x, position[2] + y}) then
          return false
        end
      end
    end
    return true
  end

  --search the entire place for possible treasure positions
  for x = 0, level.size[1] - treasure.size[1] do
    for y = 0, level.size[2] - treasure.size[2] do
      if canPlace({x, y}) then
        table.insert(treasureOptions, {x, y})
      end
    end
  end

  if #treasureOptions == 0 then
    return false
  end
  local treasurePos = treasureOptions[math.random(1,#treasureOptions)]

  level:setTreasure(treasure, treasurePos)
  return true
end

function LevelGenerator:areaAt(position, area)
  local offsetArea = {}
  for _,tile in pairs(area) do
    table.insert(offsetArea, vec2.add(tile, position))
  end
  return offsetArea
end

function LevelGenerator:placeToolAdjacent(level, toolTiles, coverTiles, avoidTiles, tool)
  local toolArea = tool:tileArea()
  local placementOptions = {}

  for x = 0, level.size[1] - tool.size[1] do
    for y = 0, level.size[2] - tool.size[2] do
      local area = self:areaAt({x,y}, toolArea)

      if #toolTiles == 0 or not containsAny(area, toolTiles) then
        local adjacentTiles = 0
        for _,tile in pairs(area) do
          adjacentTiles = adjacentTiles + #self:adjacentTiles(toolTiles, tile)
        end
        if (#toolTiles == 0 or adjacentTiles > 0) and containsAny(coverTiles, area) and not containsAny(avoidTiles, area) then
          table.insert(placementOptions, {adjacentTiles, {x,y}})
        end
      end
    end
  end

  if #placementOptions == 0 then return toolTiles, false end

  -- Find a placement that doesn't overlap all fossil tiles
  -- We need some fossil tiles to be uncoverable with the brush
  for _,placement in ipairs(shuffle(placementOptions)) do
    local newTiles = copy(toolTiles)
    local toolSpaces = self:areaAt(placement[2], toolArea)
    for _,tile in pairs(toolSpaces) do
      table.insert(newTiles, tile)
    end
    if not containsAll(newTiles, coverTiles) then
      return newTiles, true
    end
  end
  return toolTiles, false
end

function LevelGenerator:adjacentTiles(tiles, position)
  local adjacent = {}
  for _,tile in pairs(tiles) do
    if vec2.mag(vec2.sub(position, tile)) == 1 then
      table.insert(adjacent, tile)
    end
  end
  return adjacent
end