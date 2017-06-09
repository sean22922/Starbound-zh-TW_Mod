require "/scripts/vec2.lua"

function update(dt)
  local area = config.getParameter("broadcastArea")
  local pos1 = vec2.add(entity.position(), { area[1], area[2] })
  local pos2 = vec2.add(entity.position(), { area[3], area[4] })
  local entities = world.entityQuery(pos1, pos2, {
      includedTypes = config.getParameter("senseEntityTypes")
    })

  if #entities > 0 then
    local target = world.loadUniqueEntity(config.getParameter("targetUniqueId"))
    local functionName = config.getParameter("functionName")
    local arguments = config.getParameter("arguments")
    world.sendEntityMessage(target, functionName, table.unpack(arguments))

    stagehand.die()
  end
end
