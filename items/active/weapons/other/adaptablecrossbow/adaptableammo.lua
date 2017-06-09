AdaptableAmmo = WeaponAbility:new()

function AdaptableAmmo:init()
  self.ammoIndex = math.min(config.getParameter("ammoIndex", 1), #self.ammoTypes)
  self:adaptAbility()

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

function AdaptableAmmo:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  if not self.weapon.currentAbility and self.fireMode == (self.activatingFireMode or self.abilitySlot) then
    self:setState(self.switch)
  end
end

function AdaptableAmmo:switch()
  self.ammoIndex = (self.ammoIndex % #self.ammoTypes) + 1
  activeItem.setInstanceValue("ammoIndex", self.ammoIndex)

  self:adaptAbility()
  animator.playSound("switchAmmo")

  self.weapon:setStance(self.stances.switch)

  util.wait(self.stances.switch.duration)
end

function AdaptableAmmo:adaptAbility()
  local ability = self.weapon.abilities[self.adaptedAbilityIndex]
  util.mergeTable(ability, self.ammoTypes[self.ammoIndex])
  animator.setAnimationState("ammoType", tostring(self.ammoIndex))
end

function AdaptableAmmo:uninit()
end
