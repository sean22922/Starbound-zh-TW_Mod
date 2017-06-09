robotDashAttack = {}

--------------------------------------------------------------------------------
function robotDashAttack.enter()
  if not hasTarget() then return nil end

  local maxDashes = 1
  if currentPhase() > 2 then
    maxDashes = 2
  end

  return {
    edgeDistance = config.getParameter("robotDashAttack.edgeDistance"),
    dashDistance = config.getParameter("robotDashAttack.dashDistance"),
    dashSpeed = config.getParameter("robotDashAttack.dashSpeed"),
    windupTimer = config.getParameter("robotDashAttack.windupTime"),
    direction = util.randomDirection(),
    dashes = 0,
    dashing = false,
    maxDashes = maxDashes,
    stunned = false,
    stunTime = config.getParameter("robotDashAttack.stunTime")
  }
end

--------------------------------------------------------------------------------
function robotDashAttack.enteringState(stateData)
  animator.setAnimationState("movement", "idle")

  animator.setParticleEmitterOffsetRegion("dashstun", boundingBox())
  animator.setParticleEmitterOffsetRegion("dashParticles", boundingBox())

  monster.setActiveSkillName("robotDashAttack")
end

--------------------------------------------------------------------------------
function robotDashAttack.update(dt, stateData)
  if not hasTarget() then return true end

  if stateData.dashes >= stateData.maxDashes and not stateData.stunned then
    return true
  end

  local approachPoint = {self.spawnPosition[1] + stateData.direction * stateData.edgeDistance, self.spawnPosition[2]}
  local toApproach = world.distance(approachPoint, mcontroller.position())
  if (math.abs(toApproach[1]) < 1 or checkWalls(stateData.direction)) and stateData.dashes < stateData.maxDashes then
    stateData.dashing = true
  end

  if not stateData.dashing and not stateData.stunned then
    animator.setAnimationState("dashing", "off")
    animator.setAnimationState("movement", "move")
    move(toApproach, true)
  elseif stateData.dashing then
    mcontroller.controlFace(-stateData.direction)

    if stateData.windupTimer == config.getParameter("robotDashAttack.windupTime") then
      animator.setAnimationState("movement", "punch")
    end

    if stateData.windupTimer > 0 then
      stateData.windupTimer = stateData.windupTimer - dt
      return false
    else
      robotDashAttack.performDash(stateData, approachPoint, -stateData.direction)
    end
  elseif stateData.stunned then
    animator.setAnimationState("dashing", "stunned")
    animator.setAnimationState("movement", "idle")
    animator.setParticleEmitterActive("dashstun", true)

    stateData.stunTime = stateData.stunTime - dt
    if stateData.stunTime <= 0 then
      animator.setAnimationState("dashing", "off")
      stateData.stunned = false
    end
  end

  return false
end

function robotDashAttack.performDash(stateData, startPosition, direction)
  animator.setParticleEmitterActive("dashParticles", true)
  animator.setAnimationState("dashing", "on")
  monster.setDamageOnTouch(true)

  mcontroller.controlApproachXVelocity(direction * stateData.dashSpeed, 1000)

  local dashPoint = {startPosition[1] + direction * stateData.dashDistance, startPosition[2]}
  local toDashPoint = world.distance(dashPoint, mcontroller.position())
  local wallBlock = checkWalls(direction)

  if toDashPoint[1] * direction < 0 or wallBlock then
    animator.setParticleEmitterActive("dashParticles", false)
    animator.setAnimationState("dashing", "off")
    animator.setAnimationState("movement", "idle")
    monster.setDamageOnTouch(false)

    mcontroller.controlApproachXVelocity(0, 200)

    stateData.dashes = stateData.dashes + 1
    stateData.direction = direction
    stateData.dashing = false
    stateData.windupTimer = config.getParameter("robotDashAttack.windupTime")

    if stateData.dashes >= stateData.maxDashes and wallBlock then
      animator.burstParticleEmitter("crashing")
      animator.playSound("crash")
      stateData.stunned = true
    end
  end
end

function robotDashAttack.leavingState(stateData)
  animator.setParticleEmitterActive("dashstun", false)
  animator.setParticleEmitterActive("dashParticles", false)
  animator.setAnimationState("dashing", "off")

  monster.setDamageOnTouch(false)
  
  monster.setActiveSkillName("")
end
