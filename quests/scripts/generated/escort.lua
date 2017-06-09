require("/scripts/util.lua")
require("/quests/scripts/generated/common.lua")

function onInit()
  self.questClient:setMessageHandler("entitiesDead", onEntitiesDead)
  self.questClient:setMessageHandler("entitiesSpawned", onEntitiesSpawned)
end

function onEntitiesDead(_, _, group)
  if group ~= "targets" then return end
  quest.fail()
end

function onEntitiesSpawned(_, _, group, entityNames)
  if group == "targets" then
    assert(#entityNames == 1)

    setIndicators(entityNames)
    self.compass:setTarget("parameter", entityNames[1])
  end
end

function questInteract(entityId)
  if not quest.parameters().target then return end
  if world.entityUniqueId(entityId) ~= quest.parameters().target.uniqueId then return end

  notifyNpc("target", "followEscort")
  objective("find"):complete()
  return true
end

function conditionsMet()
  return objective("find"):isComplete()
end
