function sourceEntityAlive()
  return world.entityExists(projectile.sourceEntity()) and world.entityHealth(projectile.sourceEntity())[1] > 0
end

function update()
  if not sourceEntityAlive() then
    projectile.die()
  end
end

function destroy()
  if not sourceEntityAlive() then
    return
  end

  local monsterType = config.getParameter("monsterType")
  local damageTeam = entity.damageTeam()
  local parameters = {
    level = config.getParameter("monsterLevel", 1),
    aggressive = true,
    level = world.threatLevel(),
    damageTeam = damageTeam.team,
    damageTeamType = damageTeam.type,
    initialStatus = "blackmonsterrelease",
    behaviorConfig = {
      targetQueryRange = 150,
      keepTargetInSight = false,
      keepTargetInRange = 200
    }
  }
  parameters = sb.jsonMerge(parameters, config.getParameter("monsterParameters", {}))
  local entityId = world.spawnMonster(monsterType, mcontroller.position(), parameters)
  world.callScriptedEntity(entityId, "status.addEphemeralEffect", "blackmonsterrelease")
  local position = world.callScriptedEntity(entityId, "findGroundPosition", world.entityPosition(entityId), -10, 10, false)
  if position then
    mcontroller.setPosition(position)
    world.callScriptedEntity(entityId, "mcontroller.setPosition", position)
  end

  world.sendEntityMessage(projectile.sourceEntity(), "notify", {
    type = "monsterSpawned",
    targetId = entityId  
  })
end
