require("/scripts/messageutil.lua")
require("/scripts/quest/player.lua")
require("/quests/scripts/portraits.lua")
require("/scripts/quest/text_generation.lua")

-- This script provides the boilerplate needed to script a genrated quest.
-- You can provide any/all of these methods if you need custom functionality
-- during callbacks:
--   onInit, onUninit, onQuestOffer, onQuestDecline, onQuestStart,
--   onQuestComplete, onQuestFail, onUpdate, and conditionsMet (which returns
--   a bool).

Objective = {}
Objective.__index = Objective

function Objective:new(...)
  local instance = setmetatable({}, self)
  instance:init(...)
  return instance
end

function Objective:init(textGenerator, config)
  self.id = config.id
  self._text = textGenerator:substituteTags(config.text or "")
  storage.objectives[self.id] = storage.objectives[self.id] or false
  self.completeFn = nil
end

function Objective:setComplete(complete)
  storage.objectives[self.id] = complete
  assert(not self.completeFn)
end

function Objective:complete()
  self.completeFn = nil
  self:setComplete(true)
end

function Objective:setCompleteFn(completeFn)
  self.completeFn = completeFn
end

function Objective:isComplete()
  if self.completeFn then
    return self.completeFn() and true or false -- convert to bool
  end
  return storage.objectives[self.id]
end

function Objective:text()
  return self._text
end

Compass = {}
Compass.__index = Compass

function Compass:new(...)
  local instance = setmetatable({}, Compass)
  instance:init(...)
  return instance
end

function Compass:init(storedData)
  self.storedData = storedData
  self:_setTarget(self.storedData.targetType, self.storedData.target)
end

function Compass:onQuestWorld()
  return player.worldId() == quest.worldId() and player.serverUuid() == quest.serverUuid()
end

function Compass:angleTo(position)
  return vec2.angle(world.distance(position, entity.position()))
end

function Compass:getDirection()
  if not self:onQuestWorld() then
    return nil
  end

  local target = self.storedData.target
  local targetType = self.storedData.targetType

  if not target or not targetType or not self.targetPosition then
    return nil
  end

  return self:angleTo(self.targetPosition)
end

function Compass:setTarget(targetType, target)
  if self.storedData.targetType ~= targetType or self.storedData.target ~= target then
    self:_setTarget(targetType, target)
  end
end

function Compass:_setTarget(targetType, target)
  self.targetPosition = nil
  self.targetUniqueId = nil
  self.targetTracker = nil

  if targetType == "parameter" then
    if type(target) == "table" then
      self.targetUniqueId = util.map(target, function (paramName)
          return quest.parameters()[paramName].uniqueId
        end)
    else
      local parameter = quest.parameters()[target]
      assert(parameter.uniqueId)
      self.targetUniqueId = parameter.uniqueId
    end

  elseif targetType == "uniqueEntity" then
    self.targetUniqueId = target

  elseif targetType == "position" then
    self.targetPosition = target
  end

  self.storedData.targetType = targetType
  self.storedData.target = target
end

function Compass:update()
  if self.targetUniqueId then
    if not self.targetTracker then
      if type(self.targetUniqueId) == "table" then
        self.targetTracker = util.multipleEntityTracker(self.targetUniqueId, config.getParameter("uniqueEntityTrackerInterval", 5))
      else
        self.targetTracker = util.uniqueEntityTracker(self.targetUniqueId, config.getParameter("uniqueEntityTrackerInterval", 5))
      end
    end

    local positionUpdate = self.targetTracker()
    if positionUpdate then
      self.targetPosition = positionUpdate
    end
  end

  quest.setCompassDirection(self:getDirection())
end

function init()
  if not storage.textGenerated then
    generateQuestText()
    storage.textGenerated = true
  end
  local textGenerator = currentQuestTextGenerator()
  setPortraits(bind(textGenerator.substituteTags, textGenerator))

  self.outbox = Outbox.new("questOutbox", PlayerContactList.new("questContacts"))
  self.questClient = QuestPlayer.new("quest", self.outbox)

  storage.indicators = storage.indicators or config.getParameter("indicators", {})

  self.questClient:setEventHandler("updatePortrait", onUpdatePortrait)

  storage.objectives = storage.objectives or {}
  self.objectives = {}
  self.objectivesByKey = {}
  for i,objectiveConfig in ipairs(config.getParameter("objectives", {})) do
    objectiveConfig.id = objectiveConfig.id or string.format("objective%s", i)
    addObjective(Objective:new(textGenerator, objectiveConfig))
  end

  storage.compass = storage.compass or config.getParameter("initialCompassTarget", {})
  self.compass = Compass:new(storage.compass)

  if onInit then onInit() end

  updateObjectiveList()
end

function updateObjectiveList()
  quest.setObjectiveList(util.map(self.objectives, function (objective)
      return {objective:text(), objective:isComplete()}
    end))
end

function objective(id)
  return self.objectivesByKey[id]
end

function addObjective(objective)
  table.insert(self.objectives, objective)
  self.objectivesByKey[objective.id] = objective
end

function allObjectivesComplete()
  for _,objective in pairs(self.objectives) do
    if objective.id ~= "return" and not objective:isComplete() then
      return false
    end
  end
  return true
end

function onUpdatePortrait(uniqueId, portrait)
  for paramName, paramValue in pairs(quest.parameters()) do
    if paramValue.uniqueId == uniqueId then
      paramValue.portrait = portrait
      quest.setParameter(paramName, paramValue)
    end
  end
end

function setIndicators(indicators)
  storage.indicators = indicators
end

function uninit()
  if onUninit then onUninit() end
  self.questClient:uninit()
end

function questComplete()
  generateQuestText()
  local textGenerator = currentQuestTextGenerator()
  setPortraits(bind(textGenerator.substituteTags, textGenerator))
  self.questClient:questComplete()

  local eventName = config.getParameter("completeEvent", "completeQuest")
  local eventFields = config.getParameter("completeEventFields", {})
  eventFields.templateId = quest.templateId()
  eventFields.generated = true
  player.recordEvent(eventName, eventFields)

  if onQuestComplete then onQuestComplete() end
end

function questFail()
  self.questClient:questFail()

  if onQuestFail then onQuestFail() end
end

function questStart()
  self.questClient:questStart()

  if onQuestStart then onQuestStart() end
end

function questOffer()
  self.questClient:questOffer()

  if onQuestOffer then onQuestOffer() end
end

function questDecline()
  self.questClient:questDecline()

  if onQuestDecline then onQuestDecline() end
end

function update(dt)
  self.questClient:update()
  promises:update()

  if config.getParameter("requireTurnIn") then
    if not conditionsMet or conditionsMet() then
      quest.setCanTurnIn(true)
      quest.setIndicators(config.getParameter("turnInHidesIndicators", true) and {} or storage.indicators)

      local compassTarget = config.getParameter("turnInCompassTarget", {
          targetType = "parameter",
          target = "questGiver"
        })
      self.compass:setTarget(compassTarget.targetType, compassTarget.target)
    else
      quest.setCanTurnIn(false)
      quest.setIndicators(storage.indicators)
    end
  elseif conditionsMet and conditionsMet() then
    quest.complete()
  else
    quest.setIndicators(storage.indicators)
  end

  if onUpdate then onUpdate(dt) end

  updateObjectiveList()
  self.compass:update()
end

function notifyNpc(name, notificationType)
  if quest.parameters()[name] and quest.parameters()[name].uniqueId then
    name = quest.parameters()[name].uniqueId
  end
  self.outbox:sendMessage(name, "notify", {
      type = notificationType,
      sourceId = entity.id()
    })
end
