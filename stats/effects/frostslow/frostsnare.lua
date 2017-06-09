function init()
  animator.setParticleEmitterOffsetRegion("icetrail", mcontroller.boundBox())
  animator.setParticleEmitterActive("icetrail", true)
  effect.setParentDirectives("fade=00BBFF=0.15")

  script.setUpdateDelta(5)

  effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.15}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.1,
      speedModifier = 0.25,
      airJumpModifier = 0.85
    })
end

function uninit()

end
