function init()
  for _,particleEmitter in ipairs(config.getParameter("particleEmitters")) do
    animator.setParticleEmitterActive(particleEmitter, true)
  end
end

function update(dt)
end

function uninit()
end
