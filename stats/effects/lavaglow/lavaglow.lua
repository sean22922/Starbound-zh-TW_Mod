function init()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
  effect.setParentDirectives("fade=FF4400=0.2")
  
  script.setUpdateDelta(0)
end

function update(dt)

end

function uninit()
  
end
