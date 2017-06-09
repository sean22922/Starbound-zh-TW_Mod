function init()
  local bounds = mcontroller.boundBox()
  bounds[4] = 0
  animator.setParticleEmitterOffsetRegion("charge", bounds)
  animator.setParticleEmitterActive("charge", true)
end
