function init()
  effect.addStatModifierGroup({
    {stat = "protection", amount = config.getParameter("protection", 100)},
    {stat = "grit", amount = config.getParameter("grit", 1.0)}
  })

  script.setUpdateDelta(0)
end

function update(dt)
end

function uninit()
end
