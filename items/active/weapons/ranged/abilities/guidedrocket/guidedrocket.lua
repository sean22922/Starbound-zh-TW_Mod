require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

GuidedRocket = GunFire:new()

function GuidedRocket:new(abilityConfig)
  local primary = config.getParameter("primaryAbility")
  return GunFire.new(self, sb.jsonMerge(primary, abilityConfig))
end

function GuidedRocket:init()
  self:reset()

  self.rocketIds = {}
  self.cooldownTimer = self.fireTime
end

function GuidedRocket:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.rocketIds = util.filter(self.rocketIds, world.entityExists)
  local rocketTargetPosition = activeItem.ownerAimPosition()
  local rocketTargetDirection = nil

  if self.laserGuideLength then
    -- Shoot a ray through the rocketTargetPosition and aim the rocket towards
    -- the nearest collision
    local target = self:findLaserTarget()
    rocketTargetPosition = target.position
    rocketTargetDirection = target.direction
  end

  for _,rocketId in pairs(self.rocketIds) do
    world.callScriptedEntity(rocketId, "setTarget", rocketTargetPosition)
    world.callScriptedEntity(rocketId, "setTargetDirection", rocketTargetDirection)
  end

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if self.fireMode == "alt"
     and not self.weapon.currentAbility
     and self.cooldownTimer == 0 
     and not world.lineTileCollision(mcontroller.position(), self:firePosition())
     and status.overConsumeResource("energy", self:energyPerShot())  then
    self:setState(self.fire)
  end
end

function GuidedRocket:findLaserTarget()
  local ownerPosition = world.entityPosition(activeItem.ownerEntityId())
  local muzzlePosition = vec2.add(ownerPosition, activeItem.handPosition(self.weapon.muzzleOffset))

  local aimVector = vec2.norm(world.distance(activeItem.ownerAimPosition(), muzzlePosition))
  local lineEnd = vec2.mul(aimVector, self.laserGuideLength)
  local blocks = world.collisionBlocksAlongLine(muzzlePosition, vec2.add(muzzlePosition, lineEnd))

  if #blocks == 0 then
    return { direction = aimVector }
  end

  local minDistance = self.laserGuideLength
  local nearestCollision = nil
  for _,block in pairs(blocks) do
    local distance = vec2.mag(world.distance(block, muzzlePosition))
    if distance < minDistance then
      minDistance = distance
      nearestCollision = block
    end
  end
  return { position = nearestCollision }
end

function GuidedRocket:fire()
  table.insert(self.rocketIds, self:fireProjectile())

  animator.setAnimationState("firing", "fire")
  animator.burstParticleEmitter("altMuzzleFlash")
  animator.playSound(self.weapon.elementalType.."Guided")

  self.cooldownTimer = self.fireTime
  self:setState(self.cooldown)
end

function GuidedRocket:reset()
end
