function init()
  self.maxShieldHealth = status.stat("maxHealth") * config.getParameter("shieldHealthMultiplier")
  status.setResource("damageAbsorption", self.maxShieldHealth)

  self.active = true
  self.expirationTimer = config.getParameter("expirationTime") or 0

  addVisualEffect()
end

function update(dt)
  if not status.resourcePositive("damageAbsorption") then
    if self.active then
      removeVisualEffect()
    end

    if self.expirationTimer <= 0 then
      effect.expire()
    end
    self.expirationTimer = self.expirationTimer - dt

    self.active = false
  else
    if not self.active then
      addVisualEffect()
    end

    self.active = true
    self.expirationTimer = config.getParameter("expirationTime") or 0
  end
end

function addVisualEffect()
  if not config.getParameter("hideBorder") then effect.setParentDirectives("border=3;00FFFF99;00000000") end
  animator.setAnimationState("shield", "on")
end

function removeVisualEffect()
  animator.setAnimationState("shield", "off")
  effect.setParentDirectives("")
end

function onExpire()
  status.setResource("damageAbsorption", 0)
end
