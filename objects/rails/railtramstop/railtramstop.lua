require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  message.setHandler("railRiderPresent", function()
      stopWaiting()
    end)

  storage.waiting = storage.waiting or false
  storage.active = storage.active or false

  self.resumeSpeed = config.getParameter("resumeSpeed")

  updateActive()
end

function nodePosition()
  return util.tileCenter(entity.position())
end

function updateActive()
  object.setMaterialSpaces({{{0, 0}, (storage.active and not storage.waiting) and "metamaterial:rail" or "metamaterial:railstop"}})
  if storage.waiting then
    animator.setAnimationState("stopState", "wait")
  elseif storage.active then
    animator.setAnimationState("stopState", "on")
  else
    animator.setAnimationState("stopState", "off")
  end
end

function onInputNodeChange()
  if object.getInputNodeLevel(0) then
    if storage.waiting then
      stopWaiting()
    else
      startWaiting()
    end
  end
  updateActive()
end

function die()
  propagateCancel()
  notifyStoppedEntities()
end

function tramInStation()
  local ppos = nodePosition()
  local inStation = world.entityQuery({ppos[1] - 2.5, ppos[2] - 2.5}, {ppos[1] + 2.5, ppos[2] + 2.5},
      { includedTypes = { "mobile" }, boundMode = "metaboundbox",
        callScript = "isRailTramAt", callScriptArgs = {nodePosition()} })

  return #inStation > 0
end

function sendRidersTo(targetPosition)
  local tarVec = world.distance(targetPosition, nodePosition())
  local toDir = railDirectionFromVector(tarVec)
  -- sb.logInfo("%s sending riders from %s to %s (vec %s dir %s)", entity.id(), nodePosition(), targetPosition, tarVec, toDir)
  notifyStoppedEntities(toDir)
end

function notifyStoppedEntities(toDir)
  local ppos = nodePosition()
  local inStation = world.entityQuery({ppos[1] - 2.5, ppos[2] - 2.5}, {ppos[1] + 2.5, ppos[2] + 2.5}, { includedTypes = { "mobile" }, boundMode = "metaboundbox" })
  for _, id in pairs(inStation) do
    -- sb.logInfo("telling %s to resume", id)
    world.sendEntityMessage(id, "railResume", ppos, self.resumeSpeed, toDir)
  end
end

function startWaiting()
  if not storage.waiting and not tramInStation() then
    if storage.active then
      callConnected("propagateCancel")
    end
    -- sb.logInfo("%s started waiting", entity.id())
    storage.waiting = true
    storage.active = false
    updateActive()
    callConnected("propagateActivate", nodePosition())
  end
end

function stopWaiting()
  if storage.waiting then
    -- sb.logInfo("%s stopped waiting", entity.id())
    storage.active = false
    storage.waiting = false
    updateActive()
    callConnected("propagateCancel")
  end
end

function propagateActivate(summonPosition)
  if not storage.active and not vec2.eq(summonPosition, nodePosition()) then
    -- sb.logInfo("%s activated", entity.id())
    storage.active = true
    storage.waiting = false
    updateActive()
    sendRidersTo(summonPosition)
    callConnected("propagateActivate", summonPosition)
  end
end

function propagateCancel()
  if storage.active or storage.waiting then
    -- sb.logInfo("%s deactivated", entity.id())
    storage.active = false
    storage.waiting = false
    updateActive()
    callConnected("propagateCancel")
  end
end

function callConnected(callFunction, callData)
  for entityId, _ in pairs(object.getInputNodeIds(1)) do
    world.callScriptedEntity(entityId, callFunction, callData)
  end
  for entityId, _ in pairs(object.getOutputNodeIds(0)) do
    world.callScriptedEntity(entityId, callFunction, callData)
  end
end

function railDirectionFromVector(vec)
  local angle = math.atan(vec[2], vec[1])
  local dir = math.floor(((4 * angle) / math.pi) + 0.5) % 8 + 1

  -- shift to diagonals
  if dir == 5 then
    dir = vec[2] > 0 and 4 or 6
  elseif dir == 1 then
    dir = vec[2] > 0 and 2 or 8
  elseif dir == 7 then
    dir = vec[1] > 0 and 8 or 6
  elseif dir == 3 then
    dir = vec[1] > 0 and 2 or 4
  end

  return dir
end
