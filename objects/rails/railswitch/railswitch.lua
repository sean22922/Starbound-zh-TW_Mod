function init()
  updateActive()
end

function updateActive()
  local active = not object.isInputNodeConnected(0) or object.getInputNodeLevel(0)
  object.setMaterialSpaces(active and {{{0, 0}, "metamaterial:rail"}} or {})
  animator.setAnimationState("switch", active and "on" or "off")
  if active ~= storage.active then
    animator.playSound("switch")
  end
  storage.active = active
end

function onNodeConnectionChange()
  updateActive()
end

function onInputNodeChange()
  updateActive()
end
