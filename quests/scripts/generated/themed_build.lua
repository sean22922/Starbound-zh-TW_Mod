require("/quests/scripts/generated/common.lua")

function onInit()
  message.setHandler("colonyDeed.newHome", onNewHome)
end

function onNewHome(_, _, tenants, furniture, boundary)
  local tag = quest.parameters().tag.tag
  local amountNeeded = config.getParameter("amountOfFurnitureNeeded")

  for objectName, count in pairs(furniture) do
    local objectConfig = root.itemConfig(objectName).config
    if contains(objectConfig.itemTags or {}, tag) or contains(objectConfig.colonyTags or {}, tag) then
      amountNeeded = amountNeeded - count
      if amountNeeded <= 0 then
        quest.complete()
        return
      end
    end
  end
end
