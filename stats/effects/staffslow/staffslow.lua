function init()
  effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.3}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.4,
      speedModifier = 0.5,
      airJumpModifier = 0.7
    })
end

function uninit()

end
