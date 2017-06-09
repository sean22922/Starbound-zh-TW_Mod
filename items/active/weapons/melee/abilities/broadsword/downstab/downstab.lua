require "/scripts/util.lua"
require "/scripts/status.lua"
require "/items/active/weapons/weapon.lua"

Downstab = WeaponAbility:new()

function Downstab:init()
  self.cooldownTimer = self.cooldownTime
end

function Downstab:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if not self.weapon.currentAbility
     and self.cooldownTimer == 0
     and self.fireMode == "alt"
     and not mcontroller.onGround()
     and not status.statPositive("activeMovementAbilities")
     and status.overConsumeResource("energy", self.energyUsage) then

    self:setState(self.hold)
  end
end

function Downstab:hold()
  self.weapon:setStance(self.stances.hold)

  mcontroller.controlParameters({
    airForce = self.holdAirControl
  })

  status.setPersistentEffects("weaponMovementAbility", {{stat = "activeMovementAbilities", amount = 1}})

  util.wait(self.stances.hold.duration)

  while mcontroller.yVelocity() > self.stabVelocity and math.abs(world.gravity(mcontroller.position())) > 0 and not mcontroller.onGround() do
    coroutine.yield()
  end

  self:setState(self.stab)
end

function Downstab:stab()
  self.weapon:setStance(self.stances.stab)
  self.weapon:updateAim()
  
  animator.playSound("downstab")

  local energyDepleted = false
  local damageListener = damageListener("inflictedHits", function()
    if math.abs(world.gravity(mcontroller.position())) > 0 then
      mcontroller.setYVelocity(self.bounceYVelocity)
    end
    if status.overConsumeResource("energy", self.energyUsage) then
      self:setState(self.hold)
    else
      energyDepleted = true
    end
  end)

  local stabTimer = self.stances.stab.minStabTime
  while (stabTimer > 0 or (self.fireMode == "alt" and self:inGravity())) and not mcontroller.onGround() do
    stabTimer = stabTimer - self.dt

    local damageArea = partDamageArea("blade")
    self.weapon:setDamage(self.damageConfig, damageArea)
    if self:inGravity() then
      if mcontroller.yVelocity() > 0 then
        self:setState(self.hold)
      end

      damageListener:update()
    end

    if energyDepleted then return end

    coroutine.yield()
  end
end

function Downstab:uninit()
  status.clearPersistentEffects("weaponMovementAbility")
  self.cooldownTimer = self.cooldownTime
end


function Downstab:inGravity()
  return math.abs(world.gravity(mcontroller.position())) > 0
end