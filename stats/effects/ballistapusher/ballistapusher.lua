function init()
  effect.addStatModifierGroup({
    {stat = "maxHealth", amount = config.getParameter("healthAmount", 0)},
    {stat = "grit", amount = config.getParameter("gritAmount", 0)}
  })

  mcontroller.controlModifiers({
    speedModifier = config.getParameter("speedModifier")
  })

  script.setUpdateDelta(0)
end

function update(dt)
end

function uninit()
end
