robotPunchAttack = {}

--------------------------------------------------------------------------------
function robotPunchAttack.enter()
  if not hasTarget() then return nil end

  return {
    distanceRange = config.getParameter("robotPunchAttack.distanceRange"),
    winddownTimer = config.getParameter("robotPunchAttack.winddownTime"),
    windupTimer = config.getParameter("robotPunchAttack.windupTime"),
    punching = false
  }
end

--------------------------------------------------------------------------------
function robotPunchAttack.enteringState(stateData)
  animator.setAnimationState("movement", "idle")

  monster.setActiveSkillName("robotPunchAttack")
end

--------------------------------------------------------------------------------
function robotPunchAttack.update(dt, stateData)
  if not hasTarget() then return true end

  local toTarget = world.distance(self.targetPosition, mcontroller.position())
  local targetDir = util.toDirection(toTarget[1])

  if not stateData.punching then 
    if math.abs(toTarget[1]) > stateData.distanceRange[2] then
      animator.setAnimationState("movement", "move")
      mcontroller.controlMove(util.toDirection(toTarget[1]), true)
    elseif math.abs(toTarget[1]) < stateData.distanceRange[1] then
      mcontroller.controlMove(util.toDirection(-toTarget[1]), true)
      animator.setAnimationState("movement", "move")
      mcontroller.controlFace(targetDir)
    else
      stateData.punching = true
    end
  else
    mcontroller.controlFace(targetDir)
    if stateData.windupTimer > 0 then
      if stateData.windupTimer == config.getParameter("robotPunchAttack.windupTime") then
      animator.setAnimationState("movement", "punch")
      end
      stateData.windupTimer = stateData.windupTimer - dt
    elseif stateData.winddownTimer > 0 then
      if stateData.winddownTimer == config.getParameter("robotPunchAttack.winddownTime") then
        robotPunchAttack.punch(targetDir)
        animator.playSound("punch")
      end
      stateData.winddownTimer = stateData.winddownTimer - dt
    else
      return true
    end
  end


  return false
end

function robotPunchAttack.punch(direction)
  local projectileType = config.getParameter("robotPunchAttack.projectile.type")
  local projectileConfig = config.getParameter("robotPunchAttack.projectile.config")
  local projectileOffset = config.getParameter("robotPunchAttack.projectile.offset")
  
  if projectileConfig.power then
    projectileConfig.power = projectileConfig.power * root.evalFunction("monsterLevelPowerMultiplier", monster.level())
  end

  world.spawnProjectile(projectileType, monster.toAbsolutePosition(projectileOffset), entity.id(), {direction, 0}, true, projectileConfig)
end

function robotPunchAttack.leavingState(stateData)
  monster.setActiveSkillName("")
end
