require "/scripts/vec2.lua"

function init()
  message.setHandler("removeEffects", function()
      local category = config.getParameter("effectCategory")
      for _, uniqueId in pairs(storage.entities) do
        local entityId = world.loadUniqueEntity(uniqueId)
        if world.entityExists(entityId) then
          world.callScriptedEntity(entityId, "status.clearPersistentEffects", category)
        end
      end
    end)
end

function update(dt)
  if not storage.entities then
    local area = config.getParameter("broadcastArea")
    local pos1 = vec2.add(entity.position(), { area[1], area[2] })
    local pos2 = vec2.add(entity.position(), { area[3], area[4] })
    local region = {pos1[1], pos1[2], pos2[1], pos2[2]}
    local x = world.loadRegion(region)

    local entityTypes = config.getParameter("entityTypes")
    storage.entities = world.entityQuery(pos1, pos2, {
        includedTypes = entityTypes
      })

    if #storage.entities == 0 then
      storage.entities = nil
      return
    end

    local category = config.getParameter("effectCategory")
    local effects = config.getParameter("effects")
    for i, entityId in pairs(storage.entities) do
      local uniqueId = world.entityUniqueId(entityId)
      if not uniqueId then
        uniqueId = world.callScriptedEntity(entityId, "config.getParameter", "uniqueId") or sb.makeUuid()
        assert(uniqueId ~= nil)
        world.setUniqueId(entityId, uniqueId)
      end
      world.callScriptedEntity(entityId, "status.addPersistentEffects", category, effects)
      storage.entities[i] = uniqueId
    end
  end
end
