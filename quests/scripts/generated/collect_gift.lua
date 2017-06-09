require("/quests/scripts/generated/common.lua")

function onInit()
  self.questClient:setEventHandler({"target", config.getParameter("giftReceivedEventName")}, onGiftReceived)
end

function questInteract(entityId)
  if world.entityUniqueId(entityId) ~= quest.parameters().target.uniqueId then return end

  if not objective("collect"):isComplete() then
    notifyNpc("target", config.getParameter("requestGiftNotification"))
    return true
  end
end

function onGiftReceived(target, interactor)
  if interactor ~= entity.id() then return end
  if objective("collect"):isComplete() then return end

  local gift = quest.parameters().item.item
  player.giveItem(gift)
  setIndicators({})
  objective("collect"):complete()
end

function hasItem()
  local gift = quest.parameters().item.item
  return player.hasItem(gift)
end

function conditionsMet()
  return objective("collect"):isComplete() and hasItem()
end
