require "/scripts/util.lua"

landedState = {}

function landedState.enter()
  if storage.stateStage == "landed" then
    return {
      suffocateTimer = config.getParameter("suffocateTime", 10),
      jumpTimer = 0,
      jumpDirection = util.randomDirection()
    }
  end
end

function landedState.enteringState(stateData)
  animator.setAnimationState("movement", "panicSlow")
  setBodyDirection({stateData.jumpDirection, 0})
  monster.setDamageTeam({type = "passive"})
  monster.setDeathSound("deathPuff")
  monster.setDeathParticleBurst(config.getParameter("deathParticles"))
  monster.setDropPool(config.getParameter("landedTreasurePool", "empty"))
end

function landedState.update(dt, stateData)
  if self.inLiquid then
    despawn()
    return true
  end

  stateData.suffocateTimer = stateData.suffocateTimer - dt
  if stateData.suffocateTimer <= 0 then
    status.setResource("health", 0)
    return false
  end

  mcontroller.controlParameters({ bounceFactor = 0.6 })

  stateData.jumpTimer = stateData.jumpTimer - dt
  if mcontroller.onGround() then
    if stateData.jumpTimer <= 0 then
      stateData.jumpDirection = util.randomDirection()
      mcontroller.controlMove(stateData.jumpDirection)
      mcontroller.controlJump()
    end
  end

  if stateData.jumpTimer <= 0 then
    stateData.jumpTimer = util.randomInRange(config.getParameter("flopJumpInterval"))
  end

  return false
end

function landedState.leavingState(stateData)
  monster.setDamageTeam({type = "ghostly"})
  monster.setDeathSound()
  monster.setDeathParticleBurst()
  monster.setDropPool("empty")
end
