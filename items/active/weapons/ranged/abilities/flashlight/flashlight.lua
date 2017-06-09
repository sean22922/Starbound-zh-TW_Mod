Flashlight = WeaponAbility:new()

function Flashlight:init()
  self:reset()
end

function Flashlight:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  if self.fireMode == "alt" and self.lastFireMode ~= "alt" then
    self.active = not self.active
    animator.setLightActive("flashlight", self.active)
    animator.setLightActive("flashlightSpread", self.active)
    animator.playSound("flashlight")
  end
  self.lastFireMode = fireMode
end

function Flashlight:reset()
  animator.setLightActive("flashlight", false)
  animator.setLightActive("flashlightSpread", false)
  self.active = false
end

function Flashlight:uninit()
  self:reset()
end
