require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"

Uppercut = WeaponAbility:new()

function Uppercut:init()
  self:reset()
  self.cooldownTimer = 0
end

function Uppercut:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if self.weapon.currentAbility == nil
    and self.cooldownTimer == 0
    and self.fireMode == "alt"
    and not status.resourceLocked("energy")
    and status.resource("energy") >= self.energyUsage * (self.minChargeTime / self.chargeTime) then

    self:setState(self.windup)
  end
end

function Uppercut:windup()
  self.weapon:setStance(self.stances.windup)
  self.weapon:updateAim()

  animator.setGlobalTag("directives", "?flipx")

  local chargeTimer = 0
  while self.fireMode == "alt" and (chargeTimer == self.chargeTime or status.overConsumeResource("energy", (self.energyUsage / self.chargeTime) * self.dt)) do
    chargeTimer = math.min(self.chargeTime, chargeTimer + self.dt)

    local chargeRatio = math.sin(chargeTimer / self.chargeTime * 1.57)
    self.weapon.relativeArmRotation = util.toRadians(util.lerp(chargeRatio, {self.stances.windup.armRotation, self.stances.windup.endArmRotation}))
    self.weapon.relativeWeaponRotation = util.toRadians(util.lerp(chargeRatio, {self.stances.windup.weaponRotation, self.stances.windup.endWeaponRotation}))

    mcontroller.controlModifiers({
      runningSuppressed = true,
      jumpingSuppressed = true  
    })

    coroutine.yield()
  end

  if chargeTimer >= self.minChargeTime then
    self:setState(self.fire, chargeTimer / self.chargeTime)
  end
end

function Uppercut:fire(charge)
  self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()

  animator.setAnimationState("uppercutSwoosh", "fire")
  animator.playSound("uppercut")

  self.damageConfig.knockback = vec2.mul(self.knockback, charge)

  util.wait(self.stances.fire.duration, function(dt)
    mcontroller.controlModifiers({
      runningSuppressed = true,
      jumpingSuppressed = true  
    })

    local damageArea = partDamageArea("uppercutSwoosh")
    self.weapon:setDamage(self.damageConfig, damageArea)
  end)
  
  self.cooldownTimer = self.cooldownTime
end

function Uppercut:reset()
  animator.setGlobalTag("directives", "")
end

function Uppercut:uninit()
  self:reset()
end
