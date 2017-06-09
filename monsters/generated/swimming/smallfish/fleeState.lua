require "/scripts/util.lua"

fleeState = {}

function fleeState.enter()
  local target = util.closestValidTarget(config.getParameter("fleeTriggerDistance"))
  if target ~= 0 then
    return {
      target = target,
      fleeDistance = util.randomInRange(config.getParameter("fleeDistanceRange")),
      overrideMovement = nil
    }
  end
end

function fleeState.enterWith(args)
  if args.fleeFrom then
    return {
      target = args.fleeFrom,
      fleeDistance = util.randomInRange(config.getParameter("fleeDistanceRange")),
      overrideMovement = nil
    }
  end
end

function fleeState.update(dt, stateData)
  local toTarget = entity.distanceToEntity(stateData.target)
  local targetDist = world.magnitude(toTarget)
  if targetDist > stateData.fleeDistance then
    return true
  end

  local movement = self.movement

  if stateData.overrideMovement ~= nil then
    -- Crossing to the other side of the target if blocked in the current direction
    if util.toDirection(toTarget[1]) ~= util.toDirection(stateData.overrideMovement[1]) then
      stateData.overrideMovement = nil
    else
      movement = stateData.overrideMovement
    end
  else
    movement = { -toTarget[1], -toTarget[2] }
  end

  if util.blockSensorTest("blockedSensors", movement[1]) then
    if targetDist > config.getParameter("fleeTriggerDistance") then
      return true
    end
    stateData.overrideMovement = { -movement[1], movement[2] }
  end

  self.movementWeight = config.getParameter("fleeMovementWeight")
  self.movement = {
    util.toDirection(movement[1]),
    math.min(math.max(-0.8, movement[2]), 0.8)
  }

  return false
end
