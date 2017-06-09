function buildShipLevelCondition(config)
  local shipLevelCondition = {
    description = config.description or root.assetJson("/quests/quests.config:objectiveDescriptions.shipLevel"),
    level = config.level
  }

  function shipLevelCondition:conditionMet()
    return player.shipUpgrades().shipLevel >= self.level
  end

  function  shipLevelCondition:objectiveText()
    local objective = self.description
    objective = objective:gsub("<required>", self.level)
    objective = objective:gsub("<current>", player.shipUpgrades().shipLevel)
    return objective
  end

  return shipLevelCondition
end
