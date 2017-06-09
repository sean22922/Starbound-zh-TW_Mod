require "/scripts/util.lua"

function tileAnchors(grid, pos)
  pos = copy(pos)
  pos[1] = pos[1] < 0 and pos[1] + grid.size[1] or pos[1]
  pos[1] = pos[1] >= grid.size[1] and pos[1] - grid.size[1] or pos[1]
  return grid.tiles[tostring(pos[1])][tostring(pos[2])]
end

function claimTile(grid, pos, anchors)
  pos = copy(pos)
  pos[1] = pos[1] < 0 and pos[1] + grid.size[1] or pos[1]
  pos[1] = pos[1] >= grid.size[1] and pos[1] - grid.size[1] or pos[1]
  if not grid.tiles[tostring(pos[1])] then grid.tiles[tostring(pos[1])] = jobject() end
  grid.tiles[tostring(pos[1])][tostring(pos[2])] = anchors
end

function tileAvailable(grid, pos)
  pos = copy(pos)
  pos[1] = pos[1] < 0 and pos[1] + grid.size[1] or pos[1]
  pos[1] = pos[1] >= grid.size[1] and pos[1] - grid.size[1] or pos[1]
  if not grid.tiles[tostring(pos[1])] then return true end
  if not grid.tiles[tostring(pos[1])][tostring(pos[2])] then return true end
  return false
end

function partSize(part)
  local max = {0, 0}
  for _,tile in pairs(part.tiles) do
    if tile[1] + 1 > max[1] then
      max[1] = tile[1] + 1
    end
    if tile[2] + 1 > max[2] then
      max[2] = tile[2] + 1
    end
  end
  return max
end

function partTiles(part, pos)
  local tiles = {}
  for _,tile in pairs(part.tiles) do
    table.insert(tiles, vec2.add(pos, tile))
  end
  return tiles
end

function partTileAnchors(part, tile)
  return util.map(util.filter(part.anchors, function(a)
    return compare(a[2], tile)
  end), function(a)
    return a[1]
  end)
end

-- returns the part offset if anchored to the specified direction
function anchoredPartOffset(part, direction)
  local partAnchor = vec2.mul(direction, -1)
  for _,v in pairs(part.anchors) do
    local dir, offset = v[1], v[2]
    if compare(dir, partAnchor) then
      return vec2.mul(offset, -1)
    end
  end
end

-- A part can be placed if it doesn't overlap other parts
-- and all its anchors anchor to empty spaces or other anchors
function partAllowedAt(grid, part, tilePos)
  for _,tile in pairs(part.tiles) do
    if tile[2] + tilePos[2] < 0 or tile[2] + tilePos[2] > grid.size[2] then
      return false, {"range", vec2.add(tile, tilePos)}
    end

    if not tileAvailable(grid, vec2.add(tile, tilePos)) then
      return false, {"overlap", vec2.add(tile, tilePos)}
    end

    -- check all anchors lead to empty space or other parts' anchors
    local matchingAnchors = {}
    for _,anchor in pairs(partTileAnchors(part, tile)) do
      local anchorTo = vec2.add(vec2.add(tile, tilePos), anchor)
      if not tileAvailable(grid, anchorTo) then
        local hasMatchingAnchor = false
        for _,otherAnchor in pairs(tileAnchors(grid, anchorTo)) do
          if compare(anchor, vec2.mul(otherAnchor, -1)) then
            hasMatchingAnchor = true
            table.insert(matchingAnchors, anchorTo)
          end
        end
        if not hasMatchingAnchor then
          return false, {"invalid", vec2.add(tile, tilePos), anchor}
        end
      end
    end

    -- check the part doesn't block anchors of other parts
    for _,dir in pairs({{1, 0}, {0, 1}, {-1, 0}, {0, -1}}) do
      local neighbor = vec2.add(vec2.add(tile, tilePos), dir)
      if not tileAvailable(grid, neighbor) and not contains(matchingAnchors, neighbor) then
        for _,anchor in pairs(tileAnchors(grid, neighbor)) do
          if compare(anchor, vec2.mul(dir, -1)) then
            return false, {"blocking", neighbor, anchor}
          end
        end
      end
    end
  end
  return true
end

function allowedParts(parts, grid, tilePos)
  local parts = {}
  for partName,part in (self.partConfig.parts) do
    if part.placeable and partAllowedAt(grid, tilePos) then
      table.insert(parts, partName)
    end
  end
  return parts
end

function tileWorldPos(grid, tilePos)
  local worldPos = vec2.add(grid.worldOffset, vec2.mul(tilePos, grid.tileSize))
  return vec2.add(worldPos, vec2.mul(grid.tileBorder, tilePos))
end

-- nil means the position is at a seam between two tiles
function worldToTile(grid, worldPos)
  local relativePos = world.distance(worldPos, grid.worldOffset)
  -- no negative tile coordinates, they don't serialize well
  if relativePos[1] < 0 then
    relativePos[1] = relativePos[1] + world.size()[1]
  end
  if relativePos[1] % (grid.tileSize[1] + grid.tileBorder[1]) >= grid.tileSize[1]
     or relativePos[2] % (grid.tileSize[2] + grid.tileBorder[2]) >= grid.tileSize[2] then
    return nil
  end
 return {
    math.floor(relativePos[1] / (grid.tileSize[1] + grid.tileBorder[1])),
    math.floor(relativePos[2] / (grid.tileSize[2] + grid.tileBorder[2]))
  }
end
