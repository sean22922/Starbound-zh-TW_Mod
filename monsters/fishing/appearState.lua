appearState = {}

function appearState.enter()
  if storage.stateStage == "appear" then return {} end
end

function appearState.enteringState(stateData)
  animator.setAnimationState("movement", "swimSlow")
end

function appearState.update(dt, stateData)
  self.targetOpacity = 1

  if self.currentOpacity == 1 then
    storage.stateStage = "approach"
    return true
  end

  move(self.toLure, self.swimSpeed)

  return false
end

function appearState.leavingState(stateData)

end
