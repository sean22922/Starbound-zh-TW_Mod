require("/quests/scripts/generated/common.lua")

function onInit()
  self.questClient:setEventHandler({"target", config.getParameter("tradeAcceptedEventName")}, onTradeAccepted)
end

function questInteract(entityId)
  if world.entityUniqueId(entityId) ~= quest.parameters().target.uniqueId then return end
  if not hasGivenItems() then return end
  if objective("give"):isComplete() then return end

  notifyNpc("target", config.getParameter("requestTradeNotification"))
  return true
end

function onTradeAccepted(target, interactor)
  if interactor ~= entity.id() then return end
  
  setIndicators({})
  consumeGivenItems()

  local items = quest.parameters().receivedItems.items
  for _,item in pairs(items) do
    player.giveItem(item)
  end
  objective("give"):complete()
end

function hasGivenItems()
  return hasItems("givenItems")
end

function hasItems(itemListName)
  local items = quest.parameters()[itemListName].items
  for _,item in pairs(items) do
    if not player.hasItem(item) then
      return false
    end
  end
  return true
end

function consumeGivenItems()
  local items = quest.parameters().givenItems.items
  for _,item in pairs(items) do
    player.consumeItem(item)
  end
end

function hasReceivedItems()
  return hasItems("receivedItems")
end

function onQuestStart()
  setIndicators({"target", "givenItems"})
end

function conditionsMet()
  return objective("give"):isComplete() and hasReceivedItems()
end
