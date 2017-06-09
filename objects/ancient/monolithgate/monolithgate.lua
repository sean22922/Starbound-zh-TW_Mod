require "/scripts/util.lua"

function init()
  self.flagAnimationStates = config.getParameter("flagAnimationStates")
  object.setInteractive(false)

  message.setHandler("isOpen", function()
    return contains(world.universeFlags(), "final_gate_key") ~= false
  end)
end

function update(dt)
  local currentFlags = world.universeFlags()
  for i, flag in ipairs(currentFlags) do
    if self.flagAnimationStates[flag] then
      animator.setAnimationState(self.flagAnimationStates[flag], "on")
    end
  end

  if contains(world.universeFlags(), "final_gate_key") then
    object.setInteractive(true)
  end
end
