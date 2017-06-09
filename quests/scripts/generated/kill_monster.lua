require("/scripts/util.lua")
require("/quests/scripts/generated/common.lua")

function onInit()
  self.questClient:setMessageHandler("entitiesDead", onMonsterDeath)
  self.questClient:setMessageHandler("entitiesSpawned", onMonsterSpawned)
end

function onMonsterDeath(_, _, group)
  setIndicators({"items"})
  objective("hunt"):complete()
end

function onMonsterSpawned(_, _, group, monsterNames)
  assert(#monsterNames == 1)
  setIndicators(monsterNames)
  self.compass:setTarget("parameter", monsterNames)
end

function conditionsMet()
  if not objective("hunt"):isComplete() then
    return false
  end
  local fetchList = quest.parameters().items.items
  for _,item in ipairs(fetchList) do
    if not player.hasItem(item) then
      return false
    end
  end
  return true
end
