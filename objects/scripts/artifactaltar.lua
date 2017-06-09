function init()
  object.setInteractive(storage.interactive or config.getParameter("interactive", false))
  message.setHandler("setInteractive", function()
    object.setInteractive(true)
    storage.interactive = true
  end)
end

function onInteraction(args)
  animator.setAnimationState("artifact", "invisible")

  local universeFlag = config.getParameter("triggerUniverseFlag")
  if universeFlag then world.setUniverseFlag(universeFlag) end

  local nearNpcs = world.entityQuery(entity.position(), 100, {includedTypes={"npc"}})
  for _,npcId in pairs(nearNpcs) do
    world.sendEntityMessage(npcId, "notify", {type = "artifactTaken"})
  end

  for _,playerId in pairs(world.players()) do
    world.sendEntityMessage(playerId, config.getParameter("questMessage"))
  end
end
