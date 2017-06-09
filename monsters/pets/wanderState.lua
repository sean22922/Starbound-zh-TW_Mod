require "/scripts/util.lua"

wanderState = {}

function wanderState.enterWith(params)
  return wanderState.enter()
end

function wanderState.enter()
  return {
    wanderTimer = util.randomInRange(config.getParameter("wander.wanderTime")),
    changeDirectionTimer = util.randomInRange(config.getParameter("wander.changeDirectionTime")),
    changeDirectionWait = util.randomInRange(config.getParameter("wander.changeDirectionWait")),
    direction = util.randomDirection()
  }
end

function wanderState.enteringState(stateData)
  stateData.oldDirection = stateData.direction
end

function wanderState.update(dt, stateData)
  stateData.wanderTimer = stateData.wanderTimer - dt
  stateData.changeDirectionTimer = stateData.changeDirectionTimer - dt


  if not mcontroller.onGround() then
    setJumpState()
  elseif stateData.direction ~= 0 then
    setMovementState(false)
    --If we can't move, sit around for a bit
    if not move(stateData.direction, {run = false}) then
      stateData.oldDirection = stateData.direction
      stateData.direction = 0
      mcontroller.controlFace(-stateData.direction)
    end
  else
    setIdleState()
  end

  if stateData.changeDirectionTimer <= 0 then
    if stateData.direction == 0 then
      stateData.direction = -stateData.oldDirection
      stateData.oldDirection = stateData.direction
      stateData.changeDirectionTimer = util.randomInRange(config.getParameter("wander.changeDirectionTime"))
    else
      stateData.oldDirection = stateData.direction
      stateData.direction = 0
      stateData.changeDirectionTimer = stateData.changeDirectionWait
    end
  end

  if stateData.wanderTimer < 0 then
    return true
  else
    return false
  end
end
