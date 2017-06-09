require "/scripts/util.lua"

wanderState = {}

function wanderState.enter()
  if self.inLiquid then
    return {
      wanderDirection = {util.randomDirection(), math.random() - 0.5},
      wanderTime = util.randomInRange(config.getParameter("wanderTime", {1, 2}))
    }
  end
end

function wanderState.enteringState(stateData)
  animator.setAnimationState("movement", "swimSlow")
end

function wanderState.update(dt, stateData)
  if not self.inLiquid then return true end

  if blocked(self.surfaceSensors) and stateData.wanderDirection[2] > 0 then
    stateData.wanderDirection[2] = math.random() * -0.5
    stateData.wanderTime = math.max(stateData.wanderTime, 0.5)
  elseif blocked(self.groundSensors) and stateData.wanderDirection[2] < 0 then
    stateData.wanderDirection[2] = math.random() * 0.5
    stateData.wanderTime = math.max(stateData.wanderTime, 0.5)
  elseif blocked(self.blockedSensors) then
    stateData.wanderDirection[1] = -stateData.wanderDirection[1]
    stateData.wanderTime = math.max(stateData.wanderTime, 0.5)
  end

  move(stateData.wanderDirection)

  stateData.wanderTime = stateData.wanderTime - dt
  return stateData.wanderTime <= 0
end

function wanderState.leavingState(stateData)

end
