require "/scripts/companions/capturable.lua"
require "/scripts/util.lua"

function init()
  self.sensors = sensors.create()

  self.state = stateMachine.create({
    "moveState",
    "fleeState"
  })
  self.state.leavingState = function(stateName)
    animator.setAnimationState("movement", "idle")
  end

  monster.setAggressive(false)
  animator.setAnimationState("movement", "idle")
  capturable.init()
end

function update(dt)
  capturable.update(dt)
  self.state.update(dt)
  self.sensors.clear()
end

function shouldDie()
  return status.resource("health") <= 0 or capturable.justCaptured
end

function die()
  capturable.die()
end

function damage(args)
  if status.resourcePositive("health") then
    self.state.pickState({ targetId = args.sourceId })
  end
end

function move(direction, run)
  mcontroller.controlMove(direction, true)
end

--------------------------------------------------------------------------------
moveState = {}

function moveState.enter()
  local direction
  if math.random(100) > 50 then
    direction = 1
  else
    direction = -1
  end

  return {
    timer = util.randomInRange(config.getParameter("moveTimeRange")),
    direction = direction
  }
end

function moveState.update(dt, stateData)
  if self.sensors.blockedSensors.collision.any(true) then
    stateData.direction = -stateData.direction
  end

  animator.setAnimationState("movement", "move")
  move(stateData.direction, false)

  stateData.timer = stateData.timer - dt
  if stateData.timer <= 0 then
    return true, 1.0
  end

  return false
end

--------------------------------------------------------------------------------
fleeState = {}

function fleeState.enterWith(args)
  if args.targetId == nil then return nil end
  if self.state.stateDesc() == "fleeState" then return nil end

  return {
    targetId = args.targetId,
    timer = config.getParameter("fleeMaxTime"),
    distance = util.randomInRange(config.getParameter("fleeDistanceRange"))
  }
end

function fleeState.update(dt, stateData)
  animator.setAnimationState("movement", "run")

  local targetPosition = world.entityPosition(stateData.targetId)
  if targetPosition ~= nil then
    local toTarget = world.distance(targetPosition, mcontroller.position())
    if world.magnitude(toTarget) > stateData.distance then
      return true
    else
      stateData.direction = -toTarget[1]
    end
  end

  if stateData.direction ~= nil then
    move(stateData.direction, true)
  else
    return true
  end

  stateData.timer = stateData.timer - dt
  return stateData.timer <= 0
end
