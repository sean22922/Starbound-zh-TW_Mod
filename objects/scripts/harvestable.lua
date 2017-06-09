require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  if not storage.created then
    storage.created = world.time() - config.getParameter("startingAge", 0)
  end
  storage.startDayTime = storage.startDayTime or world.timeOfDay()
  storage.durations = storage.durations or {}

  self.timeRange = config.getParameter("activeTimeRange", {0, 1})

  setStage()
end

function update()
  setStage()

  local stateConfig = isActive() and "activeAnimationStates" or "inactiveAnimationStates"
  for stateType, state in pairs(config.getParameter(stateConfig, {})) do
    animator.setAnimationState(stateType, state)
  end
end

function onInteraction()
  dropHarvest()
end

function die()
  dropHarvest()
end

function dropHarvest()
  if self.stage.harvestPool then
    local items = root.createTreasure(self.stage.harvestPool, config.getParameter("level", world.threatLevel()))
    for _,item in pairs(items) do
      world.spawnItem(item, vec2.add(entity.position(), config.getParameter("itemDropOffset", {0, 0})))
    end
    storage.created = world.time()
    storage.startDayTime = world.timeOfDay()
    storage.durations = {}
    setStage()
  end
end

function isActive()
  local activeTime = (self.timeRange[2] - self.timeRange[1]) % 1.0
  local relativeDayTime = (world.timeOfDay() - self.timeRange[1]) % 1.0
  return relativeDayTime < activeTime
end

function setStage()
  local age = activeAge()
  local stages = config.getParameter("stages")

  for i,stage in pairs(stages) do
    self.stageIndex, self.stage = i, stage
    if not storage.durations[i] then
      storage.durations[i] = util.randomInRange(stage.duration)
    end
    if not storage.durations[i] then break end

    age = age - storage.durations[i]
    if age < 0 then
      break
    end
  end

  animator.setGlobalTag("stage", self.stageIndex)
  if self.stage.harvestPool then
    object.setInteractive(true)
  else
    object.setInteractive(false)
  end
end

function activeTimeInRange(from, to)
  -- get relative to the active time range
  local totalTime = (to - from) % 1.0
  local activeTime = (self.timeRange[2] - self.timeRange[1]) % 1.0
  local startTime = (from - self.timeRange[1]) % 1.0
  local endTime = (startTime + totalTime) % 1.0

  -- time from the start of the time range to the end of the active time
  local overlap = math.max(activeTime - startTime, 0)
  if endTime >= startTime then
    -- time range is not wrapping
    -- remove any space at the end of the activeTime from the overlap
    overlap = overlap - math.max(activeTime - endTime, 0)
  else
    -- time range is wrapping
    -- add space from the start of activeTime to the overlap
    overlap = overlap + math.min(endTime, activeTime)
  end

  return overlap
end

function activeAge()
  local activeTime = (self.timeRange[2] - self.timeRange[1]) % 1.0
  local fullDays = math.floor((world.time() - storage.created) / world.dayLength())
  local remainder = activeTimeInRange(storage.startDayTime, world.timeOfDay())

  local age = (fullDays * activeTime + remainder) * world.dayLength()
  return (fullDays * activeTime + remainder) * world.dayLength()
end
