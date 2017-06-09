function extendTable(base)
  local extendMt = {
    __index = function(t,k)
      local raw = rawget(t,k)
      if raw == nil then
        return base[k]
      else
        return raw
      end
    end
  }

  return extendMt
end

local raycaster = {
  maxSteps = 30
}

function raycaster:castRays(numRays, position, direction, hitCallback)
  for x = 0, numRays - 1 do
    --Transform
    local tmpRay = {
      numRays / 2 - x,
      numRays / 2
    }
    local ray = {
      math.cos(direction) * tmpRay[2] + -math.sin(direction) * tmpRay[1],
      math.sin(direction) * tmpRay[2] + math.cos(direction) * tmpRay[1]
    }
    ray = vec2.norm(ray)

    --Cast ray and call callback for each hit
    local distance, hit, side, textureX = self:castRay(position, ray, function(distance, hit, side, textureX)
      local realDistance = distance

      --Correct the angle to cancel fisheye distortion
      local rayAngle = direction - math.atan(ray[2], ray[1])
      distance = math.cos(math.abs(rayAngle)) * distance

      if hitCallback then
        hitCallback(x, ray, distance, realDistance, hit, side, textureX)
      end
    end)
  end
end

function raycaster:castRay(position, dirVec, hitCallback)
  local position = {position[1], position[2]} --Copy

  --Get the distance needed to travel one tile in the X or Y direction
  --local dirVec = {math.cos(direction), math.sin(direction)}
  local deltaDistX = 1 / math.abs(dirVec[1])
  if dirVec[1] == 0 then deltaDistX = 999 end --Very big number
  local deltaDistY = 1 / math.abs(dirVec[2])
  if dirVec[2] == 0 then deltaDistY = 999 end --Very big number

  local tilePos = {math.floor(position[1]), math.floor(position[2])}

  local rayLength = 0
  local hit = 0
  local step = 0
  local side = "w"
  local textureX = 0

  while (hit == 0 or self.tiles[hit].transparent) and step < self.maxSteps do
    --Distance to the next square
    local distX = tilePos[1] - position[1]
    if dirVec[1] > 0 then distX = distX + 1 end

    local distY = tilePos[2] - position[2]
    if dirVec[2] > 0 then distY = distY + 1 end

    --Line distance to the next square
    local stepX = math.abs(deltaDistX * distX)
    local stepY = math.abs(deltaDistY * distY)

    if stepX < stepY then
      if dirVec[1] > 0 then
        tilePos[1] = tilePos[1] + 1
        position[1] = tilePos[1]
        side = "w"
      else
        tilePos[1] = tilePos[1] - 1
        position[1] = tilePos[1] + 1
        side = "e"
      end
      position[2] = position[2] + stepX * dirVec[2]
      textureX = position[2] % 1
      rayLength = rayLength + stepX
    else
      if dirVec[2] > 0 then
        tilePos[2] = tilePos[2] + 1
        position[2] = tilePos[2]
        side = "s"
      else
        tilePos[2] = tilePos[2] - 1
        position[2] = tilePos[2] + 1
        side = "n"
      end
      position[1] = position[1] + stepY * dirVec[1]
      textureX = position[1] % 1
      rayLength = rayLength + stepY
    end

    if tilePos[1] >= 0 and tilePos[1] < self.level.width and tilePos[2] >= 0 and tilePos[2] < self.level.height then
      hit = self.level.tiles[index(tilePos[1], tilePos[2])]
      if hit ~= 0 and hitCallback then
        hitCallback(rayLength, hit, side, textureX)
      end
    else
      hit = 0
    end
    step = step + 1
  end

  return rayLength, hit, side, textureX
end


function createRayCaster(level, tiles)
  local newCaster = {
    level = level,
    tiles = tiles
  }

  setmetatable(newCaster, extendTable(raycaster))

  return newCaster
end
