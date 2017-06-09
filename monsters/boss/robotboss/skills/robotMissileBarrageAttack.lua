robotMissileBarrageAttack = {}

--------------------------------------------------------------------------------
function robotMissileBarrageAttack.enter()
  if not hasTarget() then return nil end

  local missileCount = config.getParameter("robotMissileBarrageAttack.missileCount")
  if currentPhase() > 2 then
    missileCount = config.getParameter("robotMissileBarrageAttack.improvedMissileCount")
  end

  return { 
    ammo = missileCount, 
    fireTimer = config.getParameter("robotMissileBarrageAttack.fireTime"),
    fireInterval = config.getParameter("robotMissileBarrageAttack.fireTime"),
    spawnOffset = config.getParameter("robotMissileBarrageAttack.spawnOffset"),
    power = config.getParameter("robotMissileBarrageAttack.power")
  }
end

--------------------------------------------------------------------------------
function robotMissileBarrageAttack.enteringState(stateData)
  animator.setAnimationState("movement", "idle")

  monster.setActiveSkillName("robotMissileBarrageAttack")
end

--------------------------------------------------------------------------------
function robotMissileBarrageAttack.update(dt, stateData)
  if not hasTarget() then return true end

  --Approach spawn position
  local toSpawn = world.distance(self.spawnPosition, mcontroller.position())
  if math.abs(toSpawn[1]) > 1 then
    animator.setAnimationState("movement", "move")

    move({toSpawn[1], 0}, true)
  --In firing position
  else
    if stateData.fireTimer <= 0 then
      local power = stateData.power * root.evalFunction("monsterLevelPowerMultiplier", monster.level())
      local missileId = world.spawnProjectile("shockhoppermissile", monster.toAbsolutePosition(stateData.spawnOffset), entity.id(), {0, 1}, false, {power = power})
      world.callScriptedEntity(missileId, "setTarget", self.targetId)

      animator.playSound("missile")

      stateData.ammo = stateData.ammo - 1
      if stateData.ammo <= 0 then return true end

      stateData.fireTimer = stateData.fireTimer + stateData.fireInterval
    end

    stateData.fireTimer = stateData.fireTimer - dt
  end
end
