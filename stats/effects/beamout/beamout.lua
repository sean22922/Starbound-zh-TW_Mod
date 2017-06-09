function init()
  animator.setAnimationState("teleport", "beamOut")
  effect.setParentDirectives("?multiply=ffffff00")
  animator.setGlobalTag("effectDirectives", status.statusProperty("effectDirectives", ""))

  local speciesTags = config.getParameter("speciesTags")
  if status.statusProperty("species") then
    animator.setGlobalTag("species", speciesTags[status.statusProperty("species")] or "")
  end
end

function onExpire()
  if config.getParameter("teleport") then
    world.callScriptedEntity(entity.id(), "performTeleport")
    world.callScriptedEntity(entity.id(), "notify", { type = "performTeleport"})
    status.addEphemeralEffect("beamin")
  end
  if config.getParameter("die") then
    status.setResource("health", 0)
  end
end
