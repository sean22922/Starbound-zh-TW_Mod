function init()
  effect.addStatModifierGroup({{stat = "maxHealth", amount = config.getParameter("healthAmount", 0)}})

  script.setUpdateDelta(0)
end

function update(dt)
end

function uninit()
end
