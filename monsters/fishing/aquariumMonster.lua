require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/stateMachine.lua"
require "/scripts/companions/capturable.lua"

function init()
  local scripts = config.getParameter("scripts")
  local states = stateMachine.scanScripts(scripts, "(%a+State)%.lua")
  self.state = stateMachine.create(states)
  self.state.autoPickState = false

  self.swimSpeed = config.getParameter("swimSpeed")
  self.swimForce = config.getParameter("aquariumSwimForce", 20)

  self.rotation = 0
  animator.setAnimationState("movement", "swimSlow")
  animator.setGlobalTag("directives", "")

  self.blockedSensors = config.getParameter("blockedSensors")
  self.surfaceSensors = config.getParameter("surfaceSensors")
  self.groundSensors = config.getParameter("groundSensors")

  self.inLiquid = true

  capturable.init()
end

function die()
  if not capturable.justCaptured then
    capturable.die()
  end
end

function shouldDie()
  return status.resource("health") <= 0 or capturable.justCaptured
end

function update(dt)
  capturable.update(dt)

  if not self.state.hasState() then
    self.state.pickState()
    self.state.moveStateToEnd(self.state.stateDesc())
  end

  self.state.update(dt)

  self.inLiquid = mcontroller.liquidPercentage() > 0.9
end

function move(direction)
  if not self.inLiquid then return end

  local moveDirection = vec2.norm(direction)

  -- calculate rotation
  setBodyDirection(moveDirection)

  -- move
  mcontroller.controlApproachVelocity(vec2.mul(moveDirection, self.swimSpeed), self.swimForce)
end

function blocked(sensors)
  for i, sensor in ipairs(sensors) do
    -- world.debugPoint(monster.toAbsolutePosition(sensor), "green")
    if not world.liquidAt(monster.toAbsolutePosition(sensor)) then
      return true
    end
  end

  return false
end

function setBodyDirection(direction)
  if direction[2] ~= 0 then
    local rotateAmount = vec2.angle(direction)
    if direction[1] < 0 then rotateAmount = math.pi - rotateAmount end
    self.rotation = rotateAmount
  else
    self.rotation = 0
  end
  animator.rotateGroup("all", self.rotation)
  mcontroller.controlFace(direction[1])
  mcontroller.setRotation(self.rotation * mcontroller.facingDirection())
end
