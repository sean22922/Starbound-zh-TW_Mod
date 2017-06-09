require("/quests/scripts/generated/common.lua")
require("/quests/scripts/generated/note_generation.lua")

function onInit()
  self.questClient:setEventHandler({"target", config.getParameter("tradeAcceptedEventName")}, onTradeAccepted)
  self.questClient:setEventHandler({"questGiver", config.getParameter("stockAcceptedEventName")}, onStockAccepted)
end

function questInteract(entityId)
  local uniqueId = world.entityUniqueId(entityId)
  if uniqueId == quest.parameters().target.uniqueId then
    return onTargetInteraction()
  elseif uniqueId == quest.parameters().questGiver.uniqueId then
    return onQuestGiverInteraction()
  end
end

function onTargetInteraction()
  if not hasTradedItems() then return end
  if objective("give"):isComplete() then return end

  notifyNpc("target", config.getParameter("requestTradeNotification"))
  return true
end

function onTradeAccepted(target, interactor)
  if interactor ~= entity.id() then return end
  
  setIndicators({"questGiver"})
  consumeTradedItems()

  local parcelDescriptionConfig = config.getParameter("parcelDescription")
  local parcelNameConfig = config.getParameter("parcelName")
  local description = generateParcelText(parcelDescriptionConfig)
  local shortdescription = generateParcelText(parcelNameConfig)
  player.giveItem({
      name = "parcel",
      count = 1,
      parameters = {
          questTag = quest.questId(),
          description = description,
          shortdescription = shortdescription
        }
    })
  objective("give"):complete()
end

function onQuestGiverInteraction()
  if not hasParcel() then return end

  notifyNpc("questGiver", config.getParameter("stockDeliveredNotification"))
  return true
end

function onStockAccepted(target, interactor)
  if interactor ~= entity.id() then return end
  player.consumeItemWithParameter("questTag", quest.questId(), 1)
  quest.complete()
end

function hasTradedItems()
  local items = quest.parameters().tradedItems.items
  for _,item in pairs(items) do
    if not player.hasItem(item) then
      return false
    end
  end
  return true
end

function consumeTradedItems()
  local items = quest.parameters().tradedItems.items
  for _,item in pairs(items) do
    player.consumeItem(item)
  end
end

function hasParcel()
  return player.hasItemWithParameter("questTag", quest.questId())
end

function onQuestStart()
  setIndicators({"target", "tradedItems"})
end

function conditionsMet()
  return objective("give"):isComplete() and hasParcel()
end
