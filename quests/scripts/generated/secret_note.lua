require("/quests/scripts/generated/common.lua")
require("/quests/scripts/generated/note_generation.lua")

function onInit()
  self.questClient:setEventHandler({"target", "secretShared"}, onSecretShared)
end

function questInteract(entityId)
  if world.entityUniqueId(entityId) ~= quest.parameters().target.uniqueId then return end
  if not playerHasNote("message") then return end

  notifyNpc("target", "shareSecret")
  return true
end

function onSecretShared(target, interactor)
  if interactor ~= entity.id() then return end
  if not playerHasNote("message") then return end

  player.consumeItemWithParameter("questTag", noteTag("message"), 1)
  player.giveItem(generateTaggedNoteItem("response", config.getParameter("responseNote")))
  setIndicators({})
  objective("give"):complete()
end

function onQuestStart()
  player.giveItem(generateTaggedNoteItem("message", config.getParameter("secretNote")))
end

function onQuestComplete()
  player.consumeItemWithParameter("questTag", noteTag("response"), 1)
end

function playerHasNote(tagSuffix)
  return player.hasItemWithParameter("questTag", noteTag(tagSuffix))
end

function conditionsMet()
  return playerHasNote("response")
end
