require("/quests/scripts/generated/common.lua")

function onInit()
  self.questClient:setEventHandler({"victimDeed", "objectRemoved"}, onObjectStolen)
end

function onObjectStolen(deedUniqueId, objectName)
  if quest.parameters().objectItem.item.name == objectName then
    objective("steal"):complete()
  end
end

function requiredItems()
  return {quest.parameters().objectItem.item}
end

function conditionsMet()
  if not objective("steal"):isComplete() then return false end
  for _,item in ipairs(requiredItems()) do
    if not player.hasItem(item) then
      return false
    end
  end
  return true
end
