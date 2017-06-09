require "/scripts/util.lua"

idleState = {}

function idleState.enter()
  if self.inLiquid then
    return {
      idleTime = util.randomInRange(config.getParameter("idleTime", {2, 6}))
    }
  end
end

function idleState.enteringState(stateData)
  animator.setAnimationState("movement", "swimIdle")
  -- setBodyDirection({mcontroller.facingDirection(), 0})
end

function idleState.update(dt, stateData)
  if not self.inLiquid or blocked(self.blockedSensors) then return true end

  stateData.idleTime = stateData.idleTime - dt
  return stateData.idleTime <= 0
end

function idleState.leavingState(stateData)

end
