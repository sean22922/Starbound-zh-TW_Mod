require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.spawningColor = config.getParameter("spawningColor")
  self.leadSpawningOffset = config.getParameter("leadSpawningOffset")
  self.spawningOffset = config.getParameter("spawningOffset")

  self.lampOffset = config.getParameter("lampOffset")

  self.range = config.getParameter("bossRange", 10)
  self.direction = config.getParameter("circleDirection", 1)
  self.tangentialVelocity = mcontroller.baseParameters().flySpeed
  self.tangentialVelocityApproachMultiplier = config.getParameter("tangentialVelocityApproachMultiplier", 5.0)
  self.centripetalVelocityMultiplier = config.getParameter("centripetalVelocityMultiplier", 1.0)
  self.maxCentripetalVelocity = config.getParameter("maxCentripetalVelocity", 10)
  self.centripetalForce = config.getParameter("centripetalForce", 200)
  self.healTimer = 0

  self.projectileType = config.getParameter("missileProjectileType")
  self.leftMissileOffset = config.getParameter("leftMissileOffset")
  self.rightMissileOffset = config.getParameter("rightMissileOffset")

  mcontroller.controlFace(1)

  monster.setDamageOnTouch(true)

  message.setHandler("setLeadProjector", function(_, _, ...)
    setLeadProjector(...)
  end)
  message.setHandler("startSpawnSequence", function()
    self.spawning = true
    monster.setAggressive(false)
  end)
  message.setHandler("stopSpawnSequence", function()
    animator.setLightColor("lamp", config.getParameter("lampColors")[self.projectorIndex])
    animator.setLightActive("boosterglow", true)
    animator.setAnimationState("visibility", "visible")
    self.spawning = false
    monster.setAggressive(true)
  end)
  message.setHandler("destroy", function()
    self.boss = nil
    status.setResource("health", 0)
  end)
  message.setHandler("setSpeed", function(_, _, speed)
    self.tangentialVelocity = speed
  end)
  message.setHandler("fireMissiles", function(_, _, targetId, power)
    self.fire = coroutine.create(fireMissiles)

    -- Call it once to pass in target and power
    coroutine.resume(self.fire, targetId, power)
  end)
  message.setHandler("heal", function()
    self.healTimer = config.getParameter("healTime", 1.0)
    status.addEphemeralEffect("maxprotection", self.healTimer)

    animator.setAnimationState("projector", "heal")
    status.setResourcePercentage("health", 1.0)
  end)
end

function setLeadProjector(bossId, masterId, index, projectorCount)
  self.boss = bossId
  self.leadProjector = masterId
  self.projectorIndex = index
  self.projectorCount = projectorCount

  animator.setLightColor("lamp", config.getParameter("lampColors")[self.projectorIndex])
end

function fireMissiles(targetId, power)
  -- First wait until the angle is lower than the apex of the orbit
  while currentAngle() > math.pi/2 do coroutine.yield() end

  -- Then wait until at the apex
  while currentAngle() < math.pi/2 do coroutine.yield() end

  -- Then fire
  local offset = self.leftMissileOffset
  local missileId = world.spawnProjectile(self.projectileType, vec2.add(mcontroller.position(), self.leftMissileOffset), entity.id(), {-1,0}, false, { power = power })
  world.callScriptedEntity(missileId, "setTarget", targetId)

  missileId = world.spawnProjectile(self.projectileType, vec2.add(mcontroller.position(), self.rightMissileOffset), entity.id(), {1,0}, false, { power = power })
  world.callScriptedEntity(missileId, "setTarget", targetId)

  animator.setAnimationState("projector", "fired")
  animator.burstParticleEmitter("leftMissileLaunch")
  animator.burstParticleEmitter("rightMissileLaunch")
  animator.playSound("missileLaunch")
end

function currentAngle()
  local bossPosition = world.entityPosition(self.boss)
  return vec2.angle(world.distance(mcontroller.position(), bossPosition))
end

function update(dt)
  mcontroller.controlFace(1)

  -- Orphaned projectors should die silently
  if not self.boss then
    status.setResource("health", 0)
    return
  end

  -- Projectors fall down when they die, except the last one which falls down when the boss is gone
  if not world.entityExists(self.boss) or (self.projectorCount > 1 and not status.resourcePositive("health")) then
    monster.setDeathSound(config.getParameter("deathSound"))
    monster.setDeathParticleBurst(config.getParameter("deathParticles"))
    mcontroller.controlParameters({
      gravityEnabled = true,
      collisionPoly = { {1, 1}, {1, -1}, {-1, -1}, {-1, 1} }
    })
    return
  end

  local bossPosition = world.entityPosition(self.boss)
  -- Rotate lamp
  local bossAngle = vec2.angle(world.distance(bossPosition, mcontroller.position()))
  local lampOffset = self.lampOffset
  animator.resetTransformationGroup("lamp")
  animator.rotateTransformationGroup("lamp", bossAngle)
  animator.translateTransformationGroup("lamp", lampOffset)

  -- Show health state
  if self.healTimer > 0 then
    self.healTimer = math.max(self.healTimer - dt, 0)
  else
    animator.setAnimationState("projector", "idle")
    if status.resourcePercentage("health") > 0.75 then
      animator.setGlobalTag("health", "full")
    elseif status.resourcePercentage("health") > 0.25 then
      animator.setGlobalTag("health", "medium")
    else
      animator.setGlobalTag("health", "low")
    end
  end

  if self.spawning then
    spawnSequence()
    return
  end

  -- Fire missiles
  if self.fire and coroutine.status(self.fire) then coroutine.resume(self.fire) end

  -- Movement
  local tangentialVelocity = self.tangentialVelocity

  -- Adjust angular velocity relative to lead projector
  if self.leadProjector ~= entity.id() and world.entityExists(self.leadProjector) then
    local leadAngle = vec2.angle(world.distance(world.entityPosition(self.leadProjector), bossPosition))
    local goalAngle = leadAngle + (self.projectorIndex - 1) * (math.pi*2 / self.projectorCount)

    local selfAngle = vec2.angle(world.distance(mcontroller.position(), bossPosition))
    local toGoalAngle = self.direction * util.angleDiff(selfAngle, goalAngle)
    tangentialVelocity = tangentialVelocity + toGoalAngle * self.tangentialVelocityApproachMultiplier
  end

  circleBoss(tangentialVelocity)
end

function spawnSequence()
  local approachPosition = mcontroller.position()
  local bossPosition = world.entityPosition(self.boss)

  if self.leadProjector == entity.id() then
    animator.setLightColor("lamp", self.spawningColor)
    approachPosition = vec2.add(bossPosition, self.leadSpawningOffset)
  else
    animator.setLightColor("lamp", {0, 0, 0})
    animator.setLightActive("boosterglow", false)
    animator.setAnimationState("visibility", "invisible")
    approachPosition = vec2.add(bossPosition, self.spawningOffset)
  end

  local toApproach = world.distance(approachPosition, mcontroller.position())
  if world.magnitude(toApproach) > 1 then
    mcontroller.controlFly(toApproach)
  else
    mcontroller.controlFly({0,0})
  end
end

function circleBoss(tangentialVelocity)
  local toBoss = world.distance(world.entityPosition(self.boss), mcontroller.position())

  -- Move perpendicular to the boss direction
  local bossVelocity = world.entityVelocity(self.boss)
  local perpendicular = vec2.rotate(toBoss, -self.direction * math.pi/2)
  local relativeVelocity = vec2.add(vec2.mul(vec2.norm(perpendicular), tangentialVelocity), bossVelocity) -- Velocity is relative to boss
  mcontroller.controlApproachVelocity(relativeVelocity, mcontroller.baseParameters().airForce)

  -- Keep at desired range
  local speed = (world.magnitude(toBoss) - self.range) * self.centripetalVelocityMultiplier -- Smooths movement
  local maxSpeed = self.maxCentripetalVelocity
  speed = util.clamp(speed, -maxSpeed, maxSpeed)
  mcontroller.controlApproachVelocityAlongAngle(vec2.angle(toBoss), speed, self.centripetalForce)
end

function shouldDie()
  return not self.boss or mcontroller.onGround()
end
