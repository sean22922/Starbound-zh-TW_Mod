require "/scripts/util.lua"

function init()
  object.setInteractive(false)
  animator.setAnimationState("switchState", "on")
end

function update(dt)
  if world.isVisibleToPlayer(object.boundBox()) then
    return nil
  end
  local npcSpecies = util.randomFromList(config.getParameter("spawner.npcSpeciesOptions"))
  local npcType = util.randomFromList(config.getParameter("spawner.npcTypeOptions"))
  local npcParameter = util.randomFromList(config.getParameter("spawner.npcParameterOptions"))
  npcParameter.scriptConfig = { spawnedBy = object.position() }
  world.spawnNpc(object.toAbsolutePosition({ 0.0, 2.0 }), npcSpecies, npcType, math.max(object.level(), 1), nil, npcParameter);
  object.smash()
end
