function init()
  local bounds = mcontroller.boundBox()
  animator.setParticleEmitterOffsetRegion("flames", {bounds[1], bounds[2] + 0.2, bounds[3], bounds[2] + 0.3})
end

function update(dt)
  animator.setParticleEmitterActive("flames", config.getParameter("particles", true) and mcontroller.onGround() and mcontroller.running())
  mcontroller.controlModifiers({
      speedModifier = 1.5
    })
end

function uninit()
  
end
