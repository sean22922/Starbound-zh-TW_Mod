require "/scripts/vec2.lua"

EvilEye = WeaponAbility:new()

function EvilEye:init()
  self.cooldownTimer = self.cooldownTime
  self.beams = jarray()

  self.weapon.onLeaveAbility = function ()
    self.beams = jarray()
    activeItem.setScriptedAnimationParameter("beams", self.beams)
    animator.setAnimationState("eyeState", "idle")
    animator.setAnimationState("lance", "idle")
    self.weapon:setStance(self.stances.idle)
  end
end

function EvilEye:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  activeItem.setScriptedAnimationParameter("beams", self.beams)

  if self:fireHeld() and not self.weapon.currentAbility and self.cooldownTimer == 0 and status.overConsumeResource("energy", self.initialEnergyUsage) then
    self:setState(self.search)
  end
end

function EvilEye:fireHeld()
  return self.fireMode == (self.activatingFireMode or self.abilitySlot)
end

function EvilEye:search()
  self.beams = jarray()
  for i = 1, self.beamCount do
    local beam = copy(self.beam)
    beam.offset = vec2.add(beam.offset, self.weapon.muzzleOffset)
    beam.angularVelocity = util.toRadians(math.random(table.unpack(beam.angularVelocity)))
    beam.angle = (math.random() * 2 - 1) * util.toRadians(self.beamMaxAngle)
    table.insert(self.beams, beam)
  end

  self.weapon:setStance(self.stances.fire)
  animator.setAnimationState("eyeState", "scan")

  self.targetEntityId = nil
  local elapsed = 0

  while self:fireHeld() do
    if not status.overConsumeResource("energy", self.energyUsagePerSecond * self.dt) then
      break
    end

    elapsed = elapsed + self.dt
    if elapsed > self.windupTime then
      for _,beam in pairs(self.beams) do
        local startPosition = self:beamStartPosition(beam)
        local endPosition = self:beamEndPosition(beam, startPosition)
        self.targetEntityId = self:findTargetEntity(startPosition, endPosition)
        if self.targetEntityId then
          self:setState(self.focus)
          return
        end
      end
    end

    for _,beam in pairs(self.beams) do
      beam.angle = beam.angle + beam.angularVelocity * self.dt
      if math.abs(beam.angle) > util.toRadians(self.beamMaxAngle) then
        beam.angularVelocity = -beam.angularVelocity
      end
    end

    coroutine.yield()
  end

  if self.targetEntityId and world.entityExists(self.targetEntityId) then
    self:setState(self.focus)
  end
end

-- Return world coordinates for the start of the given beam
function EvilEye:beamStartPosition(beam)
  local ownerPosition = world.entityPosition(activeItem.ownerEntityId())
  local offset = vec2.add(self.weapon.muzzleOffset, beam and beam.offset or {0, 0})
  return vec2.add(ownerPosition, activeItem.handPosition(offset))
end

-- Return world coordinates of the nearest block the given beam collides with
-- (or the end of the beam if it doesn't collide with anything)
function EvilEye:beamEndPosition(beam, startPosition)
  local aimVector = vec2.rotate({self.weapon.aimDirection, 0}, self.weapon.aimDirection * (self.weapon.aimAngle + self.weapon.relativeArmRotation) + beam.angle)
  local endPosition = vec2.add(startPosition, vec2.mul(aimVector, beam.length))

  local blocks = world.collisionBlocksAlongLine(startPosition, endPosition)

  local minDistance = beam.length
  for _,block in pairs(blocks) do
    local distance = vec2.mag(world.distance(block, startPosition))
    if distance < minDistance then
      minDistance = distance
      endPosition = vec2.add(startPosition, vec2.mul(aimVector, distance))
    end
  end
  return endPosition
end

-- Return the EntityId of the nearest valid target hit by a ray between the
-- two given positions.
function EvilEye:findTargetEntity(startPosition, endPosition)
  local entities = world.entityQuery(startPosition, endPosition, {
      line = {startPosition, endPosition},
      includedTypes = {"creature"}
    })

  for _,entityId in pairs(entities) do
    if world.entityCanDamage(activeItem.ownerEntityId(), entityId) then
      return entityId
    end
  end
  return nil
end

function EvilEye:rotateArmTowardsTarget(angularFraction)
  local ownerPosition = world.entityPosition(activeItem.ownerEntityId())
  local targetPosition = world.entityPosition(self.targetEntityId)
  local toTarget = world.distance(targetPosition, ownerPosition)
  local angleToTarget = vec2.angle({math.abs(toTarget[1]), toTarget[2]})
  local directionToTarget = toTarget[1] / math.abs(toTarget[1])

  self.weapon.aimDirection = directionToTarget
  activeItem.setFacingDirection(directionToTarget)

  local angleDiff = angleToTarget - (self.weapon.aimAngle + self.weapon.relativeArmRotation)
  self.weapon.relativeArmRotation = self.weapon.relativeArmRotation + angleDiff / (angularFraction or 1)
end

function EvilEye:focus()
  for i = 1, self.focusIterations do
    for _,beam in pairs(self.beams) do
      beam.angle = beam.angle / self.focusRate
    end

    if self.targetEntityId and world.entityExists(self.targetEntityId) then
      self:rotateArmTowardsTarget(self.focusRate)
    end

    coroutine.yield()
  end

  if self.targetEntityId and world.entityExists(self.targetEntityId) then
    self:setState(self.fire)
  end
end

function EvilEye:fire()
  animator.setAnimationState("lance", "fire")

  local elapsedTime = 0

  while world.entityExists(self.targetEntityId) and self:fireHeld() and not status.resourceLocked("energy") do
    local position = world.entityPosition(self.targetEntityId)
    if world.lineCollision(self:beamStartPosition(), position, {"Block"}) then
      break
    end

    local timeMultiplier = root.evalFunction("evilEyeTimeMultiplier", elapsedTime)

    local projectile = self.projectiles[math.random(#self.projectiles)]
    local params = {
        damageTeam = world.entityDamageTeam(activeItem.ownerEntityId()),
        powerMultiplier = activeItem.ownerPowerMultiplier() * timeMultiplier
      }
    util.mergeTable(params, projectile.parameters)

    world.spawnProjectile(
        projectile.type,
        position,
        activeItem.ownerEntityId(),
        {0, 0},
        false,
        params
      )

    util.wait(self.repeatFireTime, function (dt)
        elapsedTime = elapsedTime + dt
        if not world.entityExists(self.targetEntityId) or not self:fireHeld() then
          return true
        end
        if not status.overConsumeResource("energy", self.energyUsagePerSecond * self.dt) then
          return true
        end
        self:rotateArmTowardsTarget()
      end)
  end

  self.beams = jarray()
  self.cooldownTimer = self.cooldownTime
  animator.setAnimationState("eyeState", "idle")
end

function EvilEye:uninit()
end
