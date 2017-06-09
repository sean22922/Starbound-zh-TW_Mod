require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.controlForce = config.getParameter("controlForce")
  self.maxSpeed = config.getParameter("maxSpeed")
end

function update(dt)
  mcontroller.setRotation(math.atan(mcontroller.velocity()[2], mcontroller.velocity()[1]))
  if self.target and world.entityExists(self.target) then
    local toTarget = world.distance(world.entityPosition(self.target), mcontroller.position())
    toTarget = vec2.norm(toTarget)

    if not self.initialTargetDir then
      self.initialTargetDir = { util.toDirection(toTarget[1]), util.toDirection(toTarget[2]) }
    end

    if vec2.dot(self.initialTargetDir, toTarget) < 0 then
      self.passedTarget = true
    end

    if not self.passedTarget then
      mcontroller.approachVelocity(vec2.mul(toTarget, self.maxSpeed), self.controlForce)
    end
  end
end

function setTarget(targetId)
  self.target = targetId
end
