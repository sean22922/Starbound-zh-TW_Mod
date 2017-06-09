require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"

function init()
  animator.setGlobalTag("bladeDirectives", "")

  self.blinkTime = config.getParameter("blinkTime")
  self.blinkTimer = util.randomInRange(self.blinkTime)

  self.twitchMagnitude = config.getParameter("twitchMagnitude")
  self.twitchTime = config.getParameter("twitchTime")
  self.twitchTimer = util.randomInRange(self.twitchTime)

  self.weapon = Weapon:new()

  self.weapon:addTransformationGroup("weapon", {0,0}, util.toRadians(config.getParameter("baseWeaponRotation", 0)))
  self.weapon:addTransformationGroup("swoosh", {0,0}, math.pi/2)

  local primaryAbility = getPrimaryAbility()
  self.weapon:addAbility(primaryAbility)

  local secondaryAttack = getAltAbility()
  if secondaryAttack then
    self.weapon:addAbility(secondaryAttack)
  end

  self.weapon:init()
end

function update(dt, fireMode, shiftHeld)
  self.blinkTimer = math.max(0, self.blinkTimer - dt)
  if self.blinkTimer == 0 then
    if self.weapon.currentAbility == nil then
      animator.setAnimationState("eye", "blink")
    end
    self.blinkTimer = util.randomInRange(self.blinkTime)
  end

  self.twitchTimer = math.max(0, self.twitchTimer - dt)
  if self.twitchTimer == 0 then
    local twitchOffset = vec2.rotate({math.random() * self.twitchMagnitude, 0}, math.random() * 2 * math.pi)
    animator.resetTransformationGroup("pupil")
    animator.translateTransformationGroup("pupil", twitchOffset)
    self.twitchTimer = util.randomInRange(self.twitchTime)
  end

  self.weapon:update(dt, fireMode, shiftHeld)
end

function uninit()
  self.weapon:uninit()
end
