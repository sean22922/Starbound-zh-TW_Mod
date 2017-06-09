require("/scripts/util.lua")
require("/quests/scripts/generated/common.lua")

function onInit()
  self.questClient:setMessageHandler("entitiesDead", quest.complete)
  self.questClient:setMessageHandler("entitiesSpawned", onEnemiesSpawned)
  self.questClient:setEventHandler({"target", "death"}, onTargetDied)
end

function onTargetDied()
  -- Failed to protect target
  quest.fail()
end

function onEnemiesSpawned(_, _, group, entityNames)
  setIndicators(entityNames)
end

function onUpdate(dt)
  local range = config.getParameter("spawnPointObjectiveRange")
  local spawnPoint = rect.center(quest.parameters().spawnPoint.region)
  if world.magnitude(entity.position(), spawnPoint) < range then
    objective("findPlace"):complete()
  end
end
