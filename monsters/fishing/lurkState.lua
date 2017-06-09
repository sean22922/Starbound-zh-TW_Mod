require "/scripts/vec2.lua"
require "/scripts/util.lua"

lurkState = {}

function lurkState.enter()
  if storage.stateStage == "approach" then
    return {
      hookDistance = config.getParameter("hookDistance", 1.5),
      lurkTimer = util.randomInRange(config.getParameter("lurkTimeRange", {16, 24}))
    }
  end
end

function lurkState.enteringState(stateData)

end

function lurkState.update(dt, stateData)
  if not self.lureId then
    storage.stateStage = "disappear"
    return true
  end

  stateData.lurkTimer = math.max(0, stateData.lurkTimer - dt)

  local lureDist = vec2.mag(self.toLure)
  if lureDist < config.getParameter("biteDistance", 4) then
    if stateData.lookTimer then
      stateData.lookTimer = stateData.lookTimer - dt
    else
      stateData.lookTimer = util.randomInRange(config.getParameter("lookTimeRange", 2, 3))
    end

    if stateData.lookTimer <= 0 then
      if lureDist < stateData.hookDistance then
        world.sendEntityMessage(self.ownerId, "fishOn", entity.id())
        storage.stateStage = "hooked"
        return true
      else
        animator.setAnimationState("movement", "swimFast")
        move(self.toLure, self.biteSpeed)
      end
    elseif stateData.lurkTimer == 0 then
      storage.stateStage = "disappear"
      return true
    elseif lureDist > stateData.hookDistance then
      animator.setAnimationState("movement", "swimSlow")
      move(self.toLure, self.swimSpeed)
    else
      animator.setAnimationState("movement", "swimIdle")
      setBodyDirection(self.toLure)
    end
  else
    if stateData.lurkTimer == 0 then
      storage.stateStage = "disappear"
      return true
    else
      stateData.lookTimer = nil
      animator.setAnimationState("movement", "swimIdle")
      setBodyDirection(self.toLure)
    end
  end

  return false
end

function lurkState.leavingState(stateData)

end
