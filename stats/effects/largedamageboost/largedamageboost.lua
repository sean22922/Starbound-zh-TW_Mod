function init()
  local bounds = mcontroller.boundBox()
  animator.setParticleEmitterOffsetRegion("boostparticles", {bounds[1], bounds[2] + 0.2, bounds[3], bounds[4] - 0.2})
  animator.setParticleEmitterActive("boostparticles", true)
  effect.addStatModifierGroup({
    {stat = "powerMultiplier", effectiveMultiplier = config.getParameter("powerMultiplier", 5.0)}
  })

  self.directives = config.getParameter("directives")
end

function update(dt)
  effect.setParentDirectives(self.directives)
end

function uninit()
end
