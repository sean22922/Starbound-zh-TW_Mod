function init()
  object.setInteractive(false)
  if storage.state == nil then
    output(false)
  else
    output(storage.state)
  end
end

function output(state)
  if storage.state ~= state then
    storage.state = state
    object.setAllOutputNodes(state)
    if state then
      animator.setAnimationState("switchState", "on")
    else
      animator.setAnimationState("switchState", "off")
    end
  else
  end
end

function update(dt)
  if object.getInputNodeLevel(1) then
    output(object.getInputNodeLevel(0))
  end
end
