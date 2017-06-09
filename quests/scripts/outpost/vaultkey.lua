require("/quests/scripts/portraits.lua")
require("/quests/scripts/questutil.lua")

function init()
  self.targetWorlds = {}
  for i, worldId in ipairs(config.getParameter("targetWorlds")) do
    self.targetWorlds[worldId] = true
  end

  storage.hasKey = storage.hasKey or false

  setupIndicators()
  setupObjectives()
  setPortraits()
end

function questStart()
  world.sendEntityMessage("vaultkeytrader", "openVaults")
end

function questComplete()
  questutil.questCompleteActions()
end

function update(dt)
  if storage.hasKey then
    if self.targetWorlds[world.type()] then
      quest.complete()
    end
  elseif player.hasItem("vaultkey") then
    storage.hasKey = true
    setupIndicators()
    setupObjectives()
  end
end

function uninit()

end

function setupIndicators()
  if not storage.hasKey then
    quest.setParameter("keytrader", {type = "entity", uniqueId = "vaultkeytrader"})
    quest.setIndicators({"keytrader"})
  else
    quest.setIndicators({})
  end
end

function setupObjectives()
  if not storage.hasKey then
    quest.setObjectiveList(config.getParameter("objectiveLists.obtainKey"))
  else
    quest.setObjectiveList(config.getParameter("objectiveLists.enterVault"))
  end
end
