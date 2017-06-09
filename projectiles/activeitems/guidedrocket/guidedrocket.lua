require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.trailProjectile = config.getParameter("trailProjectile")
  self.trailDistance = config.getParameter("trailDistance")
  self.lastTrailPosition = mcontroller.position()
end

function update(dt)
  local targetOffset = self.targetDirection
  local currentAngle = math.atan(mcontroller.velocity()[2], mcontroller.velocity()[1])

  if self.targetPosition then
    targetOffset = world.distance(self.targetPosition, mcontroller.position())
  end

  if targetOffset then
    local angleDelta = util.wrapAngle(math.atan(targetOffset[2], targetOffset[1]) - currentAngle)
    if angleDelta > math.pi then angleDelta = angleDelta - 2 * math.pi end
    if angleDelta < -math.pi then angleDelta = angleDelta + 2 * math.pi end

    if math.abs(angleDelta) <= config.getParameter("maxTrackingAngle") then
      local rotateAmount = util.clamp(angleDelta, -config.getParameter("rotationRate") * dt, config.getParameter("rotationRate") * dt)
      mcontroller.setVelocity(vec2.rotate(mcontroller.velocity(), rotateAmount))
    end
  end

  if self.trailProjectile and world.magnitude(mcontroller.position(), self.lastTrailPosition) >= self.trailDistance then
    world.spawnProjectile(self.trailProjectile, mcontroller.position(), projectile.sourceEntity(), {0,0}, false)
    self.lastTrailPosition = mcontroller.position()
  end
end

function setTarget(position)
  self.targetPosition = position
end

function setTargetDirection(direction)
  self.targetDirection = direction
end
