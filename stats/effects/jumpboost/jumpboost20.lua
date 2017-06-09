function init()
  local bounds = mcontroller.boundBox()
  effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = 0.2}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      airJumpModifier = 1.20
    })
end

function uninit()
  
end
