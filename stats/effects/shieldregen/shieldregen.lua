function init()
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())

  self.shieldHealthRegen = status.stat("maxShield") * config.getParameter("shieldRegenPercentage")
  self.modifierGroup = effect.addStatModifierGroup({{stat = "shieldRegen", amount = self.shieldHealthRegen}})

  self.queryDamageSince = 0
end

function update(dt)
  local damageNotifications, nextStep = status.damageTakenSince(self.queryDamageSince)
  self.queryDamageSince = nextStep
  if #damageNotifications > 0 then
    self.pauseTimer = config.getParameter("pauseOnDamage", 0)
  end

  if status.stat("maxShield") <= 0 or (status.resource("shieldHealth") >= status.stat("maxShield") and config.getParameter("expireOnFull")) then
    effect.expire()
  end

  if status.resource("shieldHealth") >= status.stat("maxShield") then
    animator.setParticleEmitterActive("embers", false)
  else
    animator.setParticleEmitterActive("embers", true)
  end
end
