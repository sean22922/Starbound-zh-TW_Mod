function init()
  self.flyingBoosterStates = config.getParameter("flyingBoosterStates")
end

function update(dt)
  -- sb.logInfo("Flying type is %s and warp phase is %s", world.flyingType(), world.warpPhase());
  local newFlyingType = world.flyingType()
  if newFlyingType ~= storage.flyingType then
    animator.setAnimationState("boosterState", self.flyingBoosterStates[newFlyingType])
    storage.flyingType = newFlyingType
  end
end
