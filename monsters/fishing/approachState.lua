require "/scripts/vec2.lua"
require "/scripts/util.lua"

approachState = {}

function approachState.enter()
  if storage.stateStage == "approach" then
    return {
      biteDistance = config.getParameter("biteDistance", 3.5),
      approachTimer = util.randomInRange(config.getParameter("approachTimeRange", {8, 14}))
    }
  end
end

function approachState.enteringState(stateData)
  animator.setAnimationState("movement", "swimSlow")
end

function approachState.update(dt, stateData)
  if not self.lureId then
    storage.stateStage = "disappear"
    return true
  end

  stateData.approachTimer = math.max(0, stateData.approachTimer - dt)

  local lureDist = vec2.mag(self.toLure)
  if lureDist < stateData.biteDistance then
    if stateData.lookTimer then
      stateData.lookTimer = stateData.lookTimer - dt
    else
      stateData.lookTimer = util.randomInRange(config.getParameter("lookTimeRange", 2, 3))
    end

    if stateData.lookTimer <= 0 then
      if lureDist < config.getParameter("hookDistance", 1.5) then
        world.sendEntityMessage(self.ownerId, "fishOn", entity.id())
        storage.stateStage = "hooked"
        return true
      else
        animator.setAnimationState("movement", "swimFast")
        move(self.toLure, self.biteSpeed)
      end
    elseif stateData.approachTimer == 0 then
      storage.stateStage = "disappear"
      return true
    else
      setBodyDirection(self.toLure)
    end
  else
    if stateData.approachTimer == 0 then
      storage.stateStage = "disappear"
      return true
    else
      stateData.lookTimer = nil
      animator.setAnimationState("movement", "swimSlow")
      move(self.toLure, self.swimSpeed)
    end
  end

  return false
end

function approachState.leavingState(stateData)

end
