require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

SuperSpinSlash = WeaponAbility:new()

function SuperSpinSlash:init()
  self.cooldownTimer = self.cooldownTime
  self:reset()
end

function SuperSpinSlash:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if self.weapon.currentAbility == nil
    and self.fireMode == "alt"
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy")
    and not status.statPositive("activeMovementAbilities") then
    
    self:setState(self.slash)
  end
end

function SuperSpinSlash:slash()
  status.setPersistentEffects("weaponMovementAbility", {{stat = "activeMovementAbilities", amount = 1}})

  local slash = coroutine.create(self.slashAction)
  coroutine.resume(slash, self)

  local movement = function()
    mcontroller.controlModifiers({runningSuppressed = true})

    if self.hover and math.abs(world.gravity(mcontroller.position())) > 0 then
      mcontroller.controlApproachYVelocity(self.hoverYSpeed, self.hoverForce)
    end
  end

  while util.parallel(slash, movement) do
    coroutine.yield()
  end
end

function SuperSpinSlash:slashAction()
  local armRotationOffset = math.random(1, #self.armRotationOffsets)
  while self.fireMode == "alt" do
    if not status.overConsumeResource("energy", self.energyUsage * (self.stances.windup.duration + self.stances.slash.duration)) then return end

    self.weapon:setStance(self.stances.windup)
    self.weapon.relativeArmRotation = self.weapon.relativeArmRotation - util.toRadians(self.armRotationOffsets[armRotationOffset])
    self.weapon:updateAim()

    util.wait(self.stances.windup.duration, function()
      return status.resourceLocked("energy")
    end)

    self.weapon.aimDirection = -self.weapon.aimDirection

    self.weapon:setStance(self.stances.slash)
    self.weapon.relativeArmRotation = self.weapon.relativeArmRotation + util.toRadians(self.armRotationOffsets[armRotationOffset])
    self.weapon:updateAim()

    armRotationOffset = armRotationOffset + 1
    if armRotationOffset > #self.armRotationOffsets then armRotationOffset = 1 end

    animator.setAnimationState("spinSwoosh", "fire", true)

    util.wait(self.stances.slash.duration, function()
      local damageArea = partDamageArea("spinSwoosh")
      self.weapon:setDamage(self.damageConfig, damageArea)
    end)
  end

  self.cooldownTimer = self.cooldownTime
end

function SuperSpinSlash:reset()
  status.clearPersistentEffects("weaponMovementAbility")
  animator.setGlobalTag("swooshDirectives", "")
end

function SuperSpinSlash:uninit()
  self:reset()
end
