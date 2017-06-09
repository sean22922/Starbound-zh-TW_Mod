--------------------------------------------------------------------------------
function init()
  self.dismounted = false

  local setAnimationState = function(stateName)
    animator.setAnimationState("mount", stateName)

    if self.dismounted then
      animator.setAnimationState("rider", "dismounted")
    else
      animator.setAnimationState("rider", stateName)
    end
  end

  self.state = stateMachine.create({
    "chargeAttack"
  })
  self.state.leavingState = function(stateName)
    setAnimationState("idle")
    monster.setDamageOnTouch(false)
  end

  monster.setAggressive(false)
  setAnimationState("idle")

  self.movement = groundMovement.create(3, 4, setAnimationState)
end

--------------------------------------------------------------------------------
function update(dt)
  self.position = mcontroller.position()

  if util.trackTarget(config.getParameter("targetNoticeRadius")) then
    monster.setAggressive(true)
    self.state.pickState()
  elseif self.targetId == nil then
    monster.setAggressive(false)
  end

  self.state.update(dt)
end

--------------------------------------------------------------------------------
function damage(args)
  if not self.dismounted then
    if status.resourcePercentage("health") < config.getParameter("dismountHealthRatio") then
      self.dismounted = true
      world.spawnNpc(self.position, "glitch", "evilknight", monster.level())
    end
  end

  if args.sourceId ~= self.targetId then
    self.targetId = args.sourceId
    self.targetPosition = world.entityPosition(self.targetId)
    self.state.pickState()
  end
end

--------------------------------------------------------------------------------
function hasTarget()
  return self.targetId ~= nil
end

--------------------------------------------------------------------------------
chargeAttack = {}

function chargeAttack.enter()
  if not hasTarget() then return nil end

  return {}
end

function chargeAttack.enteringState(stateData)
  monster.setDamageOnTouch(true)
end

function chargeAttack.update(dt, stateData)
  if not hasTarget() then return true end

  if stateData.changeDirectionTimer ~= nil then
    stateData.changeDirectionTimer = stateData.changeDirectionTimer - dt
    if stateData.changeDirectionTimer <= 0 then
      stateData.changeDirectionTimer = nil
    end
  end

  local toTarget = world.distance(self.targetPosition, self.position)
  local targetDirection = util.toDirection(toTarget[1])
  if stateData.chargeDirection == nil or world.magnitude(toTarget) > config.getParameter("chargeAttackOvershootDistance") then
    stateData.chargeDirection = targetDirection
    stateData.changeDirectionTimer = config.getParameter("changeDirectionCooldown")
  end

  mcontroller.controlFace(stateData.chargeDirection)
  if not self.movement.move(self.position, stateData.chargeDirection, stateData.chargeDirection == targetDirection, true) then
    if stateData.changeDirectionTimer == nil then
      stateData.chargeDirection = targetDirection
      stateData.changeDirectionTimer = config.getParameter("changeDirectionCooldown")
    end
  end

  return false
end
