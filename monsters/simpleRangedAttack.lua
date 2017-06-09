rangedAttack = {
  attackTimer = 0,
  fireTimer = 0,
  cooldownTimer = 0,
  firing = false,
  aimVector = {1, 0}
}

function rangedAttack.loadConfig()
  rangedAttack.setConfig(
    config.getParameter("projectileType", "bullet-1"),
    config.getParameter("projectileConfig", { power = root.evalFunction("monsterLevelPowerMultiplier", monster.level()) * 10 }),
    config.getParameter("fireInterval", 1)
  )

  rangedAttack.attackTime = config.getParameter("attackTime", 1)
  rangedAttack.cooldownTime = config.getParameter("cooldownTime", 0)
  rangedAttack.sourceOffset = config.getParameter("projectileSourcePosition", {0, 0})
end

function rangedAttack.setConfig(projectile, projectileConfig, fireInterval)
  if projectile then rangedAttack.projectile = projectile end

  if projectileConfig then
    if projectileConfig.power then
      projectileConfig.power = root.evalFunction("monsterLevelPowerMultiplier", monster.level()) * projectileConfig.power
    end
    rangedAttack.projectileConfig = projectileConfig
  end

  if fireInterval then rangedAttack.fireInterval = fireInterval end
end

function rangedAttack.aim(sourceOffset, aimVector)
  rangedAttack.sourceOffset = sourceOffset
  rangedAttack.aimVector = aimVector
end

function rangedAttack.fireOnce(projectile, projectileConfig, aimVector, trackEntity)
-- sb.logInfo("Ranged attack firing with projectile %s, position %s, direction %s, trackEntity %s, projectileConfig %s", projectile or rangedAttack.projectile, monster.toAbsolutePosition(rangedAttack.sourceOffset), aimVector or rangedAttack.aimVector, trackEntity or false, projectileConfig or rangedAttack.projectileConfig)
  world.spawnProjectile(projectile or rangedAttack.projectile, monster.toAbsolutePosition(rangedAttack.sourceOffset), entity.id(), aimVector or rangedAttack.aimVector, trackEntity or false, projectileConfig or rangedAttack.projectileConfig)
end

function rangedAttack.fireContinuous(trackEntity)
  if not rangedAttack.firing then
    rangedAttack.firing = true
    rangedAttack.attackTimer = rangedAttack.attackTime
  elseif rangedAttack.cooldownTimer <= 0 then
    rangedAttack.attackTimer = rangedAttack.attackTimer - script.updateDt()
    if rangedAttack.attackTimer <= 0 then
      rangedAttack.cooldownTimer = rangedAttack.cooldownTime
      rangedAttack.attackTimer = rangedAttack.attackTime
    else
      rangedAttack.fireTimer = rangedAttack.fireTimer - script.updateDt()
      if rangedAttack.fireTimer <= 0 then
        rangedAttack.fireOnce(nil, nil, nil, trackEntity)
        rangedAttack.fireTimer = rangedAttack.fireInterval
      end
    end
  else
    rangedAttack.cooldownTimer = rangedAttack.cooldownTimer - script.updateDt()
  end
end

function rangedAttack.stopFiring()
  rangedAttack.firing = false
end
