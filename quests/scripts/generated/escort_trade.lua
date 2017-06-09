require("/quests/scripts/generated/common.lua")

function onInit()
  self.questClient:setEventHandler({"questGiver", config.getParameter("escortCompleteEventName")}, onEscortComplete)
end

function onEscortComplete(target, interactor)
  setIndicators({})
  objective("escort"):complete()
end

function onQuestComplete()
  for _,item in pairs(quest.parameters().items.items) do
    player.giveItem(item)
  end
end

function conditionsMet()
  return objective("escort"):isComplete()
end
