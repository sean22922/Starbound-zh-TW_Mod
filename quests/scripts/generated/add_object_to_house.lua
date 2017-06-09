require("/quests/scripts/generated/common.lua")

function onInit()
  self.questClient:setEventHandler({"deed", "objectAdded"}, onObjectAdded)
end

function onObjectAdded(deedUniqueId, objectName)
  if objectName == quest.parameters().object.item.name then
    quest.complete()
  end
end
