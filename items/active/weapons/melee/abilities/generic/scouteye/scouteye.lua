require "/items/active/weapons/weapon.lua"

ScoutEye = WeaponAbility:new()

function ScoutEye:init()
  self:reset()

  self.cooldownTimer = 0
end

function ScoutEye:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if self.weapon.currentAbility == nil
     and self.fireMode == "alt"
     and self.cooldownTimer == 0
     and status.overConsumeResource("energy", self.energyUsage) then

    self:setState(self.windup)
  end
end

function ScoutEye:windup()
  self.weapon:setStance(self.stances.windup)
  self.weapon:updateAim()

  util.wait(self.stances.windup.duration)

  self:setState(self.scout)
end

function ScoutEye:scout()
  self.weapon:setStance(self.stances.scout)
  self.weapon:updateAim()

  animator.playSound("fire")

  self.scoutProjectileId = world.spawnProjectile(
      self.projectileType,
      self:firePosition(),
      activeItem.ownerEntityId(),
      self:aimVector(),
      false,
      self.projectileParameters
    )

  activeItem.setCameraFocusEntity(self.scoutProjectileId)
  animator.setAnimationState("eye", "empty")
  activeItem.emote("sleep")

  local scoutCanceled = false
  self.lastFireMode = "alt"
  while not scoutCanceled and world.entityExists(self.scoutProjectileId) do
    if self.fireMode == "alt" and self.lastFireMode ~= "alt" then
      scoutCanceled = true
      world.sendEntityMessage(self.scoutProjectileId, "kill")
    end

    self.lastFireMode = self.fireMode

    coroutine.yield()
  end

  self:reset()
  self.cooldownTimer = self.cooldownTime
end

function ScoutEye:reset()
  if self.scoutProjectileId then
    world.sendEntityMessage(self.scoutProjectileId, "kill")
  end
  activeItem.setCameraFocusEntity()
  animator.setAnimationState("eye", "open")
end

function ScoutEye:uninit()
  self:reset()
end

function ScoutEye:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.fireOffset))
end

function ScoutEye:aimVector()
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + self.weapon.relativeWeaponRotation + self.weapon.relativeArmRotation + (math.pi / 2))
  aimVector[1] = aimVector[1] * self.weapon.aimDirection
  return aimVector
end
