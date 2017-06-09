require "/scripts/util.lua"

idleState = {}

function idleState.enter()
  local idleTime = util.randomInRange(config.getParameter("idle.idleTime"))
  return {
    idleTime = idleTime,
    timer = idleTime,
  }
end

function idleState.enteringState(stateData)
end

function idleState.update(dt, stateData)
  stateData.timer = stateData.timer - dt

  setIdleState()

  if stateData.timer < 0 then
    return true, 1
  else
    return false
  end
end
