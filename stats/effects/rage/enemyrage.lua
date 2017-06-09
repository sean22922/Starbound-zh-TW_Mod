function init()
  --Power
  self.powerModifier = config.getParameter("powerModifier", 0)
  effect.addStatModifierGroup({{stat = "powerMultiplier", effectiveMultiplier = self.powerModifier}})

  --Colour
  effect.setParentDirectives("fade="..config.getParameter("color").."=0.5")
  script.setUpdateDelta(0)

  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
  animator.setParticleEmitterActive("embers", true)
end


function update(dt)

end

function uninit()

end
