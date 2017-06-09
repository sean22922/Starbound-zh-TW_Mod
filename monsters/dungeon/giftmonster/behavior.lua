require "/scripts/util.lua"

function init()
  self.state = stateMachine.create({
    "idleState",
    "bounceState",
    "moveState"
  })

  self.state.leavingState = function(stateName)
    animator.setAnimationState("movement", "idle")
    self.state.moveStateToEnd(stateName)
  end

  monster.setAggressive(false)
  monster.setDamageOnTouch(false)
  monster.setDeathParticleBurst("deathPoof")
end

--------------------------------------------------------------------------------
function update(dt)
  if util.trackTarget(config.getParameter("noticeDistance")) then
    self.state.pickState(self.targetId)
  end

  self.state.update(dt)
end

--------------------------------------------------------------------------------
function move(direction)
  mcontroller.controlMove(direction, true)
end

--------------------------------------------------------------------------------
idleState = {}

function idleState.enter()
  return { timer = util.randomInRange(config.getParameter("idleTimeRange")) }
end

function idleState.update(dt, stateData)
  stateData.timer = stateData.timer - dt
  return stateData.timer <= 0
end

--------------------------------------------------------------------------------
moveState = {}

function moveState.enter()
  return {
    direction = util.randomDirection(),
    timer = util.randomInRange(config.getParameter("moveTimeRange")),
    changeDirectionTimer = 0
  }
end

function moveState.update(dt, stateData)
  local bounds = config.getParameter("metaBoundBox")
  bounds[1] = bounds[1] + stateData.direction
  bounds[3] = bounds[3] + stateData.direction

  if world.rectTileCollision(bounds, {"Null", "Block", "Dynamic", "Slippery"}) then
    if stateData.changeDirectionTimer > 0 then
      return true
    end

    stateData.direction = -stateData.direction
    stateData.changeDirectionTimer = config.getParameter("moveChangeDirectionCooldown")
  end

  stateData.timer = stateData.timer - dt
  if animator.animationState("movement") == "idle" and stateData.timer <= 0 then
    return true
  end

  move(stateData.direction)
  animator.setAnimationState("movement", "bounce")

  if stateData.changeDirectionTimer > 0 then
    stateData.changeDirectionTimer = stateData.changeDirectionTimer - dt
  end

  return false
end

--------------------------------------------------------------------------------
bounceState = {}

function bounceState.enterWith(targetId)
  return {}
end

function bounceState.update(dt, stateData)
  if animator.animationState("movement") == "idle" then
    if self.targetId == nil then
      return true
    end

    animator.setAnimationState("movement", "bounce")
  end

  return false
end
