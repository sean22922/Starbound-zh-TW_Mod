function buildScanObjectsCondition(config)
  local scanObjectsCondition = {
    description = config.description or root.assetJson("/quests/quests.config:objectiveDescriptions.scanObjects"),
    objectValues = config.objectValues,
    targetValue = config.targetValue,
    radioMessages = config.radioMessages or {}
  }

  function scanObjectsCondition:conditionMet()
    return self.totalValue >= self.targetValue
  end

  function scanObjectsCondition:onQuestStart()
    -- check for any objects the player may already be carrying
    for objectName, value in pairs(self.objectValues) do
      if player.hasItem({name = objectName, count = 1}) then
        storage.scannedObjects[objectName] = value
      end
    end
    self:computeTotal()
    if self:conditionMet() then
      if self.radioMessages.startAlreadyComplete then
        player.radioMessage(self.radioMessages.startAlreadyComplete)
      end
    elseif self.totalValue > 0 then
      if self.radioMessages.startWithProgress then
        player.radioMessage(self.radioMessages.startWithProgress)
      end
    end
  end

  function scanObjectsCondition:onUpdate()
    for _, objectName in pairs(self:remainingObjects()) do
      if player.hasItem({name = objectName, count = 1}) then
        self:onObjectScanned(nil, nil, objectName)
      end
    end
  end

  function scanObjectsCondition:computeTotal()
    self.totalValue = 0
    for objectName, value in pairs(storage.scannedObjects) do
      self.totalValue = self.totalValue + value
    end
  end

  function scanObjectsCondition:onObjectScanned(message, isLocal, objectName)
    if self:conditionMet() then return end

    storage.scannedObjects[objectName] = self.objectValues[objectName]
    local previousTotal = self.totalValue
    self:computeTotal()
    if self.totalValue > previousTotal then
      if self:conditionMet() then
        self:uniqueProgressRadioMessage(objectName)
        self:completeRadioMessage()
      else
        if not self:uniqueProgressRadioMessage(objectName) then
          self:genericProgressRadioMessage()
        end
      end
    end
  end

  function scanObjectsCondition:remainingObjects()
    local result = jarray()

    if self:conditionMet() then return result end

    for objectName, value in pairs(self.objectValues) do
      if not storage.scannedObjects[objectName] then
        table.insert(result, objectName)
      end
    end
    return result
  end

  function scanObjectsCondition:uniqueProgressRadioMessage(objectName)
    if self.radioMessages.uniqueProgress and self.radioMessages.uniqueProgress[objectName] then
      player.radioMessage(self.radioMessages.uniqueProgress[objectName])
      return true
    end
    return false
  end

  function scanObjectsCondition:genericProgressRadioMessage()
    if self.radioMessages.genericProgress then
      player.radioMessage(self.radioMessages.genericProgress[math.random(1, #self.radioMessages.genericProgress)])
    end
  end

  function scanObjectsCondition:completeRadioMessage()
    if self.radioMessages.complete then
      player.radioMessage(self.radioMessages.complete)
    end
  end

  function scanObjectsCondition:objectiveText()
    return self.description
  end

  function scanObjectsCondition:progress()
    return math.min(1.0, self.totalValue / self.targetValue)
  end

  storage.scannedObjects = storage.scannedObjects or {} -- remember which objects we've previously scanned
  scanObjectsCondition:computeTotal()

  message.setHandler("objectScanned", function(...) scanObjectsCondition:onObjectScanned(...) end)
  message.setHandler("interestingObjects", function(...) return scanObjectsCondition:remainingObjects() end)

  return scanObjectsCondition
end
