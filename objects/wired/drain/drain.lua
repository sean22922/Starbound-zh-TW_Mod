function init()
  self.drainPos = object.position()
  if storage.state == nil then
    output(false)
  else
    output(storage.state)
  end
end

-- Change Animation
function output(state)
  if state ~= storage.state then
    storage.state = state
    if state then
      animator.setAnimationState("drainState", "on")
    else
      animator.setAnimationState("drainState", "off")
    end
  end
end

-- Removes Liquids at current position
function drain()
  if world.liquidAt(self.drainPos)then
    world.forceDestroyLiquid(self.drainPos)
  end
end

function update(dt)
  if not object.isInputNodeConnected(0) or object.getInputNodeLevel(0) then
    output(true)
    drain()
  else
    output(false)
  end
end
