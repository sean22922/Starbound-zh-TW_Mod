require("/quests/scripts/generated/common.lua")
require("/quests/scripts/generated/note_generation.lua")

function onQuestStart()
  player.giveItem(generateTaggedNoteItem("crime", config.getParameter("crimeNotice"), "Crime Notice"))
end

function questInteract(entityId)
  local targetUniqueId = quest.parameters().target.uniqueId
  if world.entityUniqueId(entityId) ~= targetUniqueId then return end
  if not storage.interacted and hasNotice() then
    notifyNpc(targetUniqueId, "collectFine")
    self.questClient:setEventHandler({"target", "fineCollected"}, onFineCollected)
    return true
  end
end

function onFineCollected(targetUniqueId, interactorEntityId)
  if interactorEntityId == entity.id() and hasNotice() then
    storage.interacted = true
    player.consumeItemWithParameter("questTag", noteTag("crime"), 1)
    player.giveItem(quest.parameters().item.item)
    objective("collect"):complete()
  end
end

function hasItem()
  return player.hasItem(quest.parameters().item.item)
end

function hasNotice()
  return player.hasItemWithParameter("questTag", noteTag("crime"))
end

function conditionsMet()
  return storage.interacted and hasItem()
end
