require("/quests/scripts/generated/common.lua")

function onInit()
  message.setHandler("colonyDeed.newHome", onNewHome)
end

function onQuestStart()
  player.giveItem({ name = "colonydeed", count = 1 })
end

function onNewHome(_, _, tenants, furniture, boundary)
  if not anyGuardTenants(tenants) then
    return
  end

  if not hasRequiredFurniture(furniture) then
    return
  end

  quest.complete()
end

function anyGuardTenants(tenants)
  for _,tenant in pairs(tenants) do
    local questGenConfig = root.npcConfig(tenant.type).scriptConfig.questGenerator or {}
    local flags = questGenConfig.flags or {}
    if flags.guard then
      return true
    end
  end
  return false
end

function hasRequiredFurniture(furniture)
  local tag = quest.parameters().tag.tag
  local amountNeeded = config.getParameter("amountOfFurnitureNeeded")

  for objectName, count in pairs(furniture) do
    local objectConfig = root.itemConfig(objectName).config
    if contains(objectConfig.itemTags or {}, tag) or contains(objectConfig.colonyTags or {}, tag) then
      amountNeeded = amountNeeded - count
      if amountNeeded <= 0 then
        return true
      end
    end
  end

  return false
end
