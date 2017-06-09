function init()
  --Health Scale
  self.energyModifier = config.getParameter("energyModifier", 0)
  effect.addStatModifierGroup({{stat = "maxEnergy", effectiveMultiplier = self.energyModifier}})
end

function update(dt)
end

function uninit()
end
