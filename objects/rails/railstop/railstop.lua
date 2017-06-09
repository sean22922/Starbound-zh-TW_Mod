require "/scripts/util.lua"

function init()
  self.resumeSpeed = config.getParameter("resumeSpeed")
  updateActive()
end

function nodePosition()
  return util.tileCenter(entity.position())
end

function updateActive()
  local active = object.getInputNodeLevel(0)
  object.setMaterialSpaces({{{0, 0}, active and "metamaterial:rail" or "metamaterial:railstop"}})
  animator.setAnimationState("stopState", active and "on" or "off")
end

function onInputNodeChange()
  if object.getInputNodeLevel(0) then
    notifyStoppedEntities()
  end
  updateActive()
end

function die()
  notifyStoppedEntities()
end

function notifyStoppedEntities()
  local ppos = nodePosition()
  local inStation = world.entityQuery({ppos[1] - 2.5, ppos[2] - 2.5}, {ppos[1] + 2.5, ppos[2] + 2.5}, { includedTypes = { "mobile" }, boundMode = "metaboundbox" })
  for _, id in pairs(inStation) do
    -- sb.logInfo("telling %s to resume", id)
    world.sendEntityMessage(id, "railResume", ppos, self.resumeSpeed)
  end
end
