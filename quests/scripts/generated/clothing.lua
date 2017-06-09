require("/quests/scripts/generated/common.lua")
require("/quests/scripts/generated/note_generation.lua")

function onInit()
  self.questClient:setEventHandler({"friend", config.getParameter("clothingCraftedEventName")}, onClothingCrafted)
  self.questClient:setEventHandler({"questGiver", config.getParameter("clothingAcceptedEventName")}, onClothingAccepted)
end

function questInteract(entityId)
  local uniqueId = world.entityUniqueId(entityId)
  if uniqueId == quest.parameters().friend.uniqueId then
    return onFriendInteraction()
  elseif uniqueId == quest.parameters().questGiver.uniqueId then
    return onQuestGiverInteraction()
  end
end

function onFriendInteraction()
  if not hasClothingIngredients() then return end
  if objective("give"):isComplete() then return end

  notifyNpc("friend", config.getParameter("requestClothingCraftNotification"))
  return true
end

function onClothingCrafted(target, interactor)
  if interactor ~= entity.id() then return end

  setIndicators({"questGiver"})
  consumeClothingIngredients()

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
  if not hasClothingParcel() then return end

  notifyNpc("questGiver", config.getParameter("wearClothingNotification"))
  return true
end

function onClothingAccepted(target, interactor)
  if interactor ~= entity.id() then return end
  player.consumeItemWithParameter("questTag", quest.questId(), 1)
  quest.complete()
end

function hasClothingIngredients()
  local ingredients = quest.parameters().clothingIngredients.items
  for _,ingredient in pairs(ingredients) do
    if not player.hasItem(ingredient) then
      return false
    end
  end
  return true
end

function consumeClothingIngredients()
  local ingredients = quest.parameters().clothingIngredients.items
  for _,ingredient in pairs(ingredients) do
    player.consumeItem(ingredient)
  end
end

function hasClothingParcel()
  return player.hasItemWithParameter("questTag", quest.questId())
end

function onQuestStart()
  setIndicators({"friend", "clothingIngredients"})
end

function conditionsMet()
  return objective("give"):isComplete() and hasClothingParcel()
end
