function init()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
  effect.setParentDirectives("fade=347857=0.8")
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.5,
      speedModifier = 0.25
    })
end

function uninit()

end
