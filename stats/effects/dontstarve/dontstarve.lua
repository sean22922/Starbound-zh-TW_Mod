function init()
  effect.addStatModifierGroup({{stat = "foodDelta", effectiveMultiplier = 0}})
  if status.isResource("food") and not status.resourcePositive("food") then
    status.setResource("food", 0.01)
  end

  script.setUpdateDelta(0)
end

function uninit()

end
