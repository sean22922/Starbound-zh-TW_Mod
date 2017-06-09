require "/scripts/util.lua"

function init()
  animator.setParticleEmitterOffsetRegion("flames", mcontroller.boundBox())
  animator.setParticleEmitterActive("flames", true)
  effect.setParentDirectives("fade=BF6666=0.5")

  
  script.setUpdateDelta(5)

  self.tickDamagePercentage = 0.025
  self.burn = util.interval(1.0, function()
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = math.floor(status.resourceMax("health") * self.tickDamagePercentage) + 1,
        damageSourceKind = "fire",
        sourceEntityId = entity.id()
      })
  end)

  effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.25}
  })
end

function update(dt)
  self.burn(dt)

  mcontroller.controlModifiers({
      groundMovementModifier = 0.5,
      speedModifier = 0.75,
      airJumpModifier = 0.75
    })
end

function uninit()
end
