require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/quests/scripts/portraits.lua"
require "/quests/scripts/questutil.lua"

function init()
  setPortraits()

  storage.complete = storage.complete or false

  self.compassUpdate = config.getParameter("compassUpdate", 0.5)

  self.mechanicUid = config.getParameter("mechanicUid")
  self.estherUid = config.getParameter("estherUid")

  self.repairQuest = config.getParameter("repairQuest")

  storage.stage = storage.stage or 1
  self.stages = {
    findMechanic,
    repairShip,
    findEsther
  }

  self.state = FSM:new()
  self.state:set(self.stages[storage.stage])
end

function questInteract(entityId)
  if self.onInteract then
    return self.onInteract(entityId)
  end
end

function questStart()
end

function update(dt)
  self.state:update(dt)

  if storage.complete then
    quest.setCanTurnIn(true)
  end
end

function questComplete()
  setPortraits()
  questutil.questCompleteActions()
end

function findMechanic()
  quest.setParameter("mechanic", {type = "entity", uniqueId = self.mechanicUid, indicator = "/interface/quests/questgiver.animation"})
  quest.setIndicators({"mechanic"})

  quest.setObjectiveList({{config.getParameter("descriptions.findMechanic"), false}})

  self.onInteract = function(entityId)
    if world.entityUniqueId(entityId) == self.mechanicUid then
      player.startQuest(self.repairQuest)
      self.onInteract = nil
      return true
    end
  end

  local findMechanic = util.uniqueEntityTracker(self.mechanicUid, self.compassUpdate)
  while not player.hasQuest(self.repairQuest) do
    questutil.pointCompassAt(findMechanic())
    coroutine.yield()
  end

  storage.stage = 2
  self.state:set(self.stages[storage.stage])
end

function repairShip()
  quest.setIndicators({})
  quest.setObjectiveList({{config.getParameter("descriptions.repairShip"), false}})
  quest.setCompassDirection(nil)

  while player.hasQuest(self.repairQuest) and not player.hasCompletedQuest(self.repairQuest) do
    coroutine.yield()
  end

  if player.hasCompletedQuest(self.repairQuest) then
    storage.stage = 3
  else
    storage.stage = 1
  end

  self.state:set(self.stages[storage.stage])
end

function findEsther()
  quest.setIndicators({})
  quest.setCompassDirection(nil)
  quest.setCanTurnIn(true)

  quest.setObjectiveList({{config.getParameter("descriptions.findEsther"), false}})

  local trackEsther = util.uniqueEntityTracker(self.estherUid, self.compassUpdate)
  while true do
    questutil.pointCompassAt(trackEsther())

    coroutine.yield()
  end
end
