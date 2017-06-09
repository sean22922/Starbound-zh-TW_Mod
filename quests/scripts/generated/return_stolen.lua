require("/quests/scripts/generated/common.lua")

function onInit()
  self.questClient:setEventHandler({"thiefDeed", "objectRemoved"}, onObjectRemoved)
end

function onObjectRemoved(deedUniqueId, objectName)
  if objective("take"):isComplete() then return end
  if quest.parameters().item.item.name == objectName then
    self.questClient:setEventHandler({"victimDeed", "objectAdded"}, onObjectAdded)
    setIndicators({"victimDeed"})
    notifyNpc("thief", "objectTaken")

    objective("take"):complete()
    self.compass:setTarget("parameter", "victimDeed")
  end
end

function onObjectAdded(deedUniqueId, objectName)
  if quest.parameters().item.item.name == objectName then
    quest.complete()
  end
end
