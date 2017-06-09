require "/scripts/vec2.lua"
require "/scripts/pathing.lua"

function init()
  animator.setAnimationState("teleport", "beamOut")
  effect.setParentDirectives("?multiply=ffffff00")
  animator.setGlobalTag("effectDirectives", status.statusProperty("effectDirectives", ""))
end

function update(dt)
end

function onExpire()
  local position = mcontroller.position()
  mcontroller.setPosition(findBeamPosition())
  status.addEphemeralEffect("beamin")
end

-- param direction
-- param run
function findBeamPosition()
  local position = mcontroller.position()
  local maxSteps = 10

  local dir = math.random(0,1) * 2 - 1
  local dirs = {dir, -dir}
  for _,direction in ipairs(dirs) do
    for i = 0, maxSteps do
      if direction > 0 then
        position[1] = math.ceil(position[1])
      end

      local yDirs = {0, 1, -1}
      local lastPosition = position[1]
      for _,yDir in ipairs(yDirs) do
        if validStandingPosition({position[1] + direction, position[2] + yDir}) and i <= maxSteps then
          position = {position[1] + direction, position[2] + yDir}
          break
        end
      end
      if position[1] == lastPosition or i == maxSteps then
        return position
      end
    end
  end
  return mcontroller.position()
end
