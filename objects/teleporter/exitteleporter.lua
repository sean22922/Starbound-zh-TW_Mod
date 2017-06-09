function onInteraction(args)
  local universeFlag = config.getParameter("setUniverseFlag")
  if universeFlag then
    world.setUniverseFlag(universeFlag)
  end
  return {config.getParameter("interactAction"), config.getParameter("interactData")}
end