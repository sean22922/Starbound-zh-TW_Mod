--Not really an attack, just some idle time between attacks
crystalIdleAttack = {}

function crystalIdleAttack.enter()
  if not hasTarget() then return nil end

  return {
    timer = 0,
    bobInterval = 0.5,
    bobHeight = 0.1,
    idleTime = config.getParameter("crystalIdleAttack.idleTime", 2.5)
  }
end

function crystalIdleAttack.enteringState(stateData)
end

function crystalIdleAttack.update(dt, stateData)
  stateData.timer = stateData.timer + dt

  crystalIdleAttack.bob(dt, stateData)

  if stateData.timer > stateData.idleTime then
    return true
  end
end

function crystalIdleAttack.bob(dt, stateData)
  local bobOffset = math.sin(((stateData.timer % stateData.bobInterval) / stateData.bobInterval) * math.pi * 2) * stateData.bobHeight
  local targetPosition = {self.spawnPosition[1], self.spawnPosition[2] + bobOffset}
  local toTarget = world.distance(targetPosition, mcontroller.position())

  mcontroller.controlApproachVelocity(vec2.mul(toTarget, 1/dt), 30)
end
