require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

EnergyOrb = WeaponAbility:new()

function EnergyOrb:init()
  self.chain = config.getParameter("chain")
  self.chain.endOffset = self.projectileOffset

  self.cooldownTimer = self.cooldownTime
end

function EnergyOrb:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if self.weapon.currentAbility == nil and self.fireMode == "alt" and self.cooldownTimer == 0 and status.overConsumeResource("energy", self.energyUsage) then
    self:setState(self.windup)
  end
end

function EnergyOrb:windup()
  self.weapon:setStance(self.stances.windup)

  animator.setAnimationState("attack", "windup")

  util.wait(self.stances.windup.duration)

  self:setState(self.extend)
end

function EnergyOrb:extend()
  self.weapon:setStance(self.stances.extend)

  animator.setAnimationState("attack", "extend")
  animator.playSound("swing")

  util.wait(self.stances.extend.duration)

  self:setState(self.fire)
end

function EnergyOrb:fire()
  self.weapon:setStance(self.stances.fire)

  local position = vec2.add(mcontroller.position(), activeItem.handPosition(self.projectileOffset))
  local aimVector = vec2.withAngle(self.weapon.aimAngle)
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  local params = {
    powerMultiplier = activeItem.ownerPowerMultiplier(),
    power = self:damageAmount()
  }
  world.spawnProjectile(self.projectileType, position, activeItem.ownerEntityId(), aimVector, false, params)

  activeItem.setScriptedAnimationParameter("chains", {self.chain})

  animator.setAnimationState("attack", "fire")
  animator.playSound("fireOrb")

  util.wait(self.stances.fire.duration)

  activeItem.setScriptedAnimationParameter("chains", nil)

  self.cooldownTimer = self.cooldownTime
end

function EnergyOrb:damageAmount()
  return self.baseDamage * config.getParameter("damageLevelMultiplier")
end

function EnergyOrb:uninit()
  animator.setAnimationState("attack", "idle")
  activeItem.setScriptedAnimationParameter("chains", nil)
end
