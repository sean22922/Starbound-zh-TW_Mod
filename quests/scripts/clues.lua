require "/scripts/util.lua"
require "/quests/scripts/questutil.lua"
require("/quests/scripts/portraits.lua")

function init()
  self.descriptions = config.getParameter("descriptions")
  self.turnInEntity = config.getParameter("turnInEntityUid")
  self.objectValues = config.getParameter("objectValues")
  self.targetValue = config.getParameter("targetValue")
  self.radioMessages = config.getParameter("radioMessages")

  self.dialogClueValue = config.getParameter("dialogClueValue")
  self.dialogClueSpecies = config.getParameter("dialogClueSpecies")
  self.clueDialog = config.getParameter("clueDialog")

  storage.scannedObjects = storage.scannedObjects or {} -- remember which objects we've previously scanned
  storage.dialogClues = storage.dialogClues or {}
  computeTotal()

  message.setHandler("objectScanned", function(...) onObjectScanned(...) end)
  message.setHandler("interestingObjects", function(...) return remainingObjects() end)
  message.setHandler("dialogClueReceived", function(...) return onDialogClue(...) end)

  self.stages = {
    findClues,
    turnIn
  }
  storage.stage = storage.stage or 1

  setPortraits()

  self.state = FSM:new()
  self.state:set(self.stages[storage.stage])
end

function questInteract(entityId)
  if storage.stage == 2 then return end

  if world.isNpc(entityId) and world.entitySpecies(entityId) == self.dialogClueSpecies then
    local damageTeam = world.entityDamageTeam(entityId)
    if damageTeam.type == "friendly" then
      world.sendEntityMessage(entityId, "notify", {type = "giveClue", sourceId = entity.id(), dialog = self.clueDialog})
    end
  end
end

function questStart()
  -- make sure to give player access to scan mode if they don't have it
  local currentInspectionTool = player.essentialItem("inspectiontool")
  if not currentInspectionTool or currentInspectionTool.name == "inspectionmode" then
    player.giveEssentialItem("inspectiontool", "scanmode")
  end

  -- check for any objects the player may already be carrying
  for objectName, value in pairs(self.objectValues) do
    if player.hasItem({name = objectName, count = 1}) then
      storage.scannedObjects[objectName] = value
    end
  end
  computeTotal()
  if self.totalValue >= self.targetValue then
    if self.radioMessages.startAlreadyComplete then
      player.radioMessage(self.radioMessages.startAlreadyComplete)
    end
  elseif self.totalValue > 0 then
    if self.radioMessages.startWithProgress then
      player.radioMessage(self.radioMessages.startWithProgress)
    end
  end
end

function questComplete()
  setPortraits()

  questutil.questCompleteActions()
end

function computeTotal()
  self.totalValue = 0
  for objectName, value in pairs(storage.scannedObjects) do
    self.totalValue = self.totalValue + value
  end
  self.totalValue = self.totalValue + (#storage.dialogClues * self.dialogClueValue)
end

function onObjectScanned(message, isLocal, objectName)
  if self.totalValue >= self.targetValue then return end

  storage.scannedObjects[objectName] = self.objectValues[objectName]
  local previousTotal = self.totalValue
  computeTotal()
  if self.totalValue > previousTotal then
    if self.totalValue >= self.targetValue then
      uniqueProgressRadioMessage(objectName)
      completeRadioMessage()
    else
      if not uniqueProgressRadioMessage(objectName) then
        genericProgressRadioMessage()
      end
    end
  end
end

function onDialogClue(_, _, dialogString)
  if self.totalValue >= self.targetValue then return end

  if not contains(storage.dialogClues, dialogString) then
    genericProgressRadioMessage()
    table.insert(storage.dialogClues, dialogString)
    computeTotal()
  end
end

function remainingObjects()
  local result = jarray()

  if self.totalValue >= self.targetValue then return result end

  for objectName, value in pairs(self.objectValues) do
    if not storage.scannedObjects[objectName] then
      table.insert(result, objectName)
    end
  end
  return result
end

function uniqueProgressRadioMessage(objectName)
  if self.radioMessages.uniqueProgress and self.radioMessages.uniqueProgress[objectName] then
    player.radioMessage(self.radioMessages.uniqueProgress[objectName])
    return true
  end
  return false
end

function genericProgressRadioMessage()
  if self.radioMessages.genericProgress then
    player.radioMessage(self.radioMessages.genericProgress[math.random(1, #self.radioMessages.genericProgress)])
  end
end

function completeRadioMessage()
  if self.radioMessages.complete then
    player.radioMessage(self.radioMessages.complete)
  end
end

function objectiveText()
  return self.description
end

function progress()
  return math.min(1.0, self.totalValue / self.targetValue)
end

function update(dt)
  self.state:update(dt)
end

function findClues()
  quest.setProgress(nil)
  quest.setObjectiveList({{self.descriptions.findClues, false}})

  while self.totalValue < self.targetValue do
    for _, objectName in pairs(remainingObjects()) do
      if player.hasItem({name = objectName, count = 1}) then
        onObjectScanned(nil, nil, objectName)
      end
    end

    quest.setProgress(math.min(1.0, self.totalValue / self.targetValue))

    coroutine.yield()
  end

  storage.stage = 2
  self.state:set(self.stages[storage.stage])
end

function turnIn()
  quest.setProgress(nil)
  quest.setObjectiveList({{self.descriptions.turnIn, false}})
  quest.setCanTurnIn(true)

  local findTurnIn = util.uniqueEntityTracker(self.turnInEntity)
  while true do
    questutil.pointCompassAt(findTurnIn())
    coroutine.yield()
  end
end
