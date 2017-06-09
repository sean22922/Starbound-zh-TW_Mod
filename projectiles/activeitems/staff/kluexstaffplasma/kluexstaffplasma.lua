require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  self.controlRotation = config.getParameter("controlRotation")
  self.rotationSpeed = 0

  self.aimPosition = mcontroller.position()

  message.setHandler("updateProjectile", function(_, _, aimPosition)
      self.aimPosition = aimPosition
      return entity.id()
    end)

  message.setHandler("kill", projectile.die)
  message.setHandler("trigger", trigger)
end

function update(dt)
  if projectile.timeToLive() > 0 then
    projectile.setTimeToLive(0.5)
  end

  if self.aimPosition then
    if self.controlRotation then
      rotateTo(self.aimPosition, dt)
    end
  end

  if self.delayTimer then
    self.delayTimer = self.delayTimer - dt
    if self.delayTimer <= 0 then
      activate()
      projectile.die()
      self.delayTimer = nil
    end
  end
end

function trigger(_, _, delayTime)
  self.delayTimer = delayTime
end

function activate()
  local rotation = mcontroller.rotation()
  world.spawnProjectile(
      "energycrystal",
      mcontroller.position(),
      projectile.sourceEntity(),
      {math.cos(rotation), math.sin(rotation)},
      false,
      {
        speed = 50,
        power = projectile.power(),
        powerMultiplier = projectile.powerMultiplier()
      })

  projectile.processAction(projectile.getParameter("explosionAction"))
end

function rotateTo(position, dt)
  local vectorTo = world.distance(position, mcontroller.position())
  local angleTo = vec2.angle(vectorTo)
  if self.controlRotation.maxSpeed then
    local currentRotation = mcontroller.rotation()
    local angleDiff = util.angleDiff(currentRotation, angleTo)
    local diffSign = angleDiff > 0 and 1 or -1

    local targetSpeed = math.max(0.1, math.min(1, math.abs(angleDiff) / 0.5)) * self.controlRotation.maxSpeed
    local acceleration = diffSign * self.controlRotation.controlForce * dt
    self.rotationSpeed = math.max(-targetSpeed, math.min(targetSpeed, self.rotationSpeed + acceleration))
    self.rotationSpeed = self.rotationSpeed - self.rotationSpeed * self.controlRotation.friction * dt

    mcontroller.setRotation(currentRotation + self.rotationSpeed * dt)
  else
    mcontroller.setRotation(angleTo)
  end
end
