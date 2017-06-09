require("/quests/scripts/generated/common.lua")

function onInit()
  self.questClient:setEventHandler({"target", config.getParameter("giftAcceptedEventName")}, onGiftAccepted)
  self.questClient:setEventHandler({"target", config.getParameter("requestAdditionToHouseEventName")}, onRequestAdditionToHouse)

  if storage.addingToHouse then
    addPlaceObjectObjective()
  end
end

function questInteract(entityId)
  if world.entityUniqueId(entityId) ~= quest.parameters().target.uniqueId then return end

  if hasGift() and not storage.giftAccepted then
    notifyNpc("target", config.getParameter("provideGiftNotification"))
    return true
  end
end

function onGiftAccepted(target, interactor)
  if interactor ~= entity.id() then return end
  if not hasGift() then return end

  local gift = quest.parameters().gift.item
  player.consumeItem(gift)

  storage.giftAccepted = true
  objective("give"):complete()
end

function addPlaceObjectObjective()
  self.questClient:setEventHandler({"recipientDeed", "objectAdded"}, onObjectAdded)
  addObjective(Objective:new(currentQuestTextGenerator(), config.getParameter("addToHouseObjective")))
end

function onRequestAdditionToHouse(target, interactor)
  if interactor ~= entity.id() then return end
  if not hasGift() then return end

  if not storage.addingToHouse then
    addPlaceObjectObjective()
  end
  storage.addingToHouse = true

  objective("give"):complete()
  self.compass:setTarget("parameter", "recipientDeed")
end

function onObjectAdded(deedUniqueId, objectName)
  if storage.addingToHouse and objectName == quest.parameters().gift.item.name then
    storage.giftAccepted = true
    notifyNpc("target", config.getParameter("objectAddedNotification"))
    objective("place"):complete()
  end
end

function hasGift()
  if storage.giftAccepted then return false end

  local gift = quest.parameters().gift.item
  return player.hasItem(gift)
end

function conditionsMet()
  return storage.giftAccepted
end

function onUpdate()
  if conditionsMet() then
    setIndicators({})
    return
  else
    local indicators = {"target"}
    if storage.addingToHouse then
      indicators[#indicators+1] = "recipientDeed"
    end
    if not hasGift() then
      indicators[#indicators+1] = "gift"
    end
    setIndicators(indicators)
  end
end
