require("/scripts/util.lua")
require("/quests/scripts/generated/common.lua")

function onInit()
  self.questClient:setEventHandler({"target", "intimidated"}, onIntimidated)

  objective("equip"):setCompleteFn(holdingRequiredItem)
end

function questInteract(entityId)
  if world.entityUniqueId(entityId) ~= quest.parameters().target.uniqueId then return end
  if objective("intimidate"):isComplete() then return end

  if holdingRequiredItem() then
    notifyNpc("target", "intimidate")
  else
    notifyNpc("target", "failToIntimidate")
  end
  return true
end

function onIntimidated(target, interactor)
  if interactor ~= entity.id() then return end
  objective("equip"):complete()
  objective("intimidate"):complete()
  setIndicators({})
end

function holdingRequiredItem()
  local requiredTag = quest.parameters().item.tag
  local primaryTags = player.primaryHandItemTags()
  local altTags = player.altHandItemTags()
  return contains(primaryTags, requiredTag) or contains(altTags, requiredTag)
end

function conditionsMet()
  return allObjectivesComplete()
end
