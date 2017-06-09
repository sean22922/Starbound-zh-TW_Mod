require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/quests/scripts/portraits.lua"
require "/quests/scripts/questutil.lua"

function init()
  self.descriptions = config.getParameter("descriptions")

  self.artifactUid = config.getParameter("artifactUid")

  self.estherUid = config.getParameter("estherUid")

  self.trackArtifact = util.uniqueEntityTracker(self.artifactUid)
  self.trackEsther = util.uniqueEntityTracker(self.estherUid)

  message.setHandler(config.getParameter("artifactMessage", "artifactTaken"), function()
    if not storage.artifact then
      storage.artifact = true
      player.playCinematic(config.getParameter("artifactCinema"))
    end
  end)

  setPortraits()
  quest.setIndicators({})
end

function questStart()
  local associatedMission = config.getParameter("associatedMission")
  if associatedMission then
    player.enableMission(associatedMission)
    player.playCinematic(config.getParameter("missionUnlockedCinema"))
    self.radioMessageTimer = 3.0
  end
end

function questComplete()
  setPortraits()
  questutil.questCompleteActions()
end

function pointCompassAt(position)
  if position then
    local direction = world.distance(position, mcontroller.position())
    quest.setCompassDirection(vec2.angle(direction))
  elseif position == nil then
    quest.setCompassDirection(nil)
  end
end

function update(dt)
  if self.radioMessageTimer then
    self.radioMessageTimer = math.max(self.radioMessageTimer - dt, 0.0)
    if self.radioMessageTimer == 0 then
      player.radioMessage(config.getParameter("missionRadioMessage"))
      self.radioMessageTimer = nil
    end
  end

  if not storage.artifact then
    quest.setObjectiveList({{self.descriptions.artifact, false}})
    pointCompassAt(self.trackArtifact())
  else
    quest.setObjectiveList({{self.descriptions.turnIn, false}})
    pointCompassAt(self.trackEsther())
    quest.setCanTurnIn(true)
  end
end
