require("/scripts/util.lua")
require("/scripts/rect.lua")
require("/quests/scripts/generated/common.lua")

function onInit()
  self.questClient:setMessageHandler("entitiesDead", onEntitiesDead)
  self.questClient:setMessageHandler("entitiesSpawned", onEntitiesSpawned)

  storage.enemyGroupCount = storage.enemyGroupCount or 0
end

function onEntitiesDead(_, _, group)
  if group ~= "enemies" then return end
  storage.enemyGroupCount = storage.enemyGroupCount - 1
  if storage.enemyGroupCount <= 0 then
    objective("kill"):complete()
    objective("findPlace"):complete()

    local notificationType = config.getParameter("enemiesDeadNotification")
    if notificationType then
      for _,victim in pairs(storage.victims or {}) do
        notifyNpc(victim, notificationType)
      end
    end
  end
end

function onEntitiesSpawned(_, _, group, entityNames)
  if group == "victims" then
    storage.victims = entityNames
    setIndicators(entityNames)
    self.compass:setTarget("parameter", entityNames)

  elseif group == "enemies" then
    storage.enemyGroupCount = storage.enemyGroupCount + 1

    if not storage.victims then
      setIndicators(entityNames)
      self.compass:setTarget("parameter", entityNames)
    end
  end
end

function onUpdate(dt)
  if not objective("findPlace"):isComplete() then
    local range = config.getParameter("spawnPointObjectiveRange")
    local spawnPoint = rect.center(quest.parameters().spawnPoint.region)
    if world.magnitude(entity.position(), spawnPoint) < range then
      objective("findPlace"):complete()
    end
  end
end

function conditionsMet()
  return objective("kill"):isComplete()
end
