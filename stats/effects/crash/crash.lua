function init()
  animator.setParticleEmitterOffsetRegion("glitch", mcontroller.boundBox())
  animator.setParticleEmitterActive("glitch", true)
  effect.setParentDirectives("fade=DDDDFF=0.5")

  status.setResource("stunned", math.max(status.resource("stunned"), effect.duration()))
  mcontroller.setVelocity({0, 0})
end

function update(dt)
  mcontroller.controlModifiers({
      facingSuppressed = true,
      movementSuppressed = true
    })
end

function uninit()
  
end
