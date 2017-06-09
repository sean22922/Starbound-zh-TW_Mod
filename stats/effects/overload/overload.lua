require "/scripts/status.lua"

function init()
  animator.setParticleEmitterOffsetRegion("sparks", mcontroller.boundBox())
  animator.setParticleEmitterActive("sparks", true)

  script.setUpdateDelta(5)

  self.charge = config.getParameter("initialCharge")
  self.maxCharge = config.getParameter("maxCharge")
  self.chargeDecay = config.getParameter("chargeDecay")
  self.chargePerHit = config.getParameter("chargePerHit")
  self.damageInterval = config.getParameter("damageInterval")
  self.fadeFactor = config.getParameter("fadeFactor")
  self.emissionRateFactor = config.getParameter("emissionRateFactor")
  self.entityId = entity.id()

  self.damageTimer = self.damageInterval

  self.damageListener = damageListener("damageTaken", function(notifications)
    for _,notification in pairs(notifications) do
      if notification.healthLost > 0 and notification.damageSourceKind == "electric" and notification.sourceEntityId ~= self.entityId then
        self.charge = math.min(self.maxCharge, self.charge + self.chargePerHit)
      end
    end
  end)
end

function update(dt)
  self.damageListener:update()

  self.charge = self.charge - (self.chargeDecay * dt)
  if self.charge <= 0 then
    effect.expire()
    return
  elseif effect.duration() < 1 then
    effect.modifyDuration(1)
  end

  animator.setParticleEmitterEmissionRate("sparks", self.charge * self.emissionRateFactor)
  effect.setParentDirectives(string.format("fade=7733AA=%.2f", self.charge * self.fadeFactor))

  self.damageTimer = math.max(0, self.damageTimer - dt)
  if self.damageTimer == 0 then
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = self.charge * self.damageInterval,
        damageSourceKind = "electric",
        sourceEntityId = entity.id()
      })
    self.damageTimer = self.damageInterval
  end
end

function uninit()

end
