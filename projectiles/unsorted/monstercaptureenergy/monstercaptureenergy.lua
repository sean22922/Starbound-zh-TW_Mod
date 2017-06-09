require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  mcontroller.applyParameters(config.getParameter("movementSettings", {}))

  self.speed = config.getParameter("speed")
  self.snapForce = config.getParameter("snapForce")
  self.controlForce = config.getParameter("controlForce")
  self.pickupDistance = config.getParameter("pickupDistance")
  self.snapDistance = config.getParameter("snapDistance")

  self.target = config.getParameter("target")
end

function update(dt)
  if not self.target or not world.entityExists(self.target) then
    projectile.die()
    return
  end

  local toTarget = world.distance(world.entityPosition(self.target), mcontroller.position())
  local targetDistance = vec2.mag(toTarget)
  if targetDistance < self.pickupDistance then
    projectile.die()
  else
    local force = self.controlForce
    if targetDistance < self.snapDistance then
      force = self.snapForce
    end
    mcontroller.approachVelocity(vec2.mul(vec2.norm(toTarget), self.speed), force)
  end
end
