tenant = {}

function tenant.evictTenant()
  tenant.despawn()
end

function tenant.despawn()
  monster.setDropPool(nil)
  monster.setDeathParticleBurst(nil)
  status.addEphemeralEffect("beamoutanddie")
end

function tenant.returnHome(reason)
  receiveNotification({ name = "returnHome", reason = reason })
end

function setupTenant(...)
  tenant.setHome(...)
end

function tenant.setHome(position, boundary)
  storage.home = {
      position = position,
      boundary = boundary
    }
  status.addEphemeralEffect("beamin")
  if findAnchor then
    -- pet anchor
    storage.anchorPosition = position
    findAnchor()
  end
end

function tenant.setGrumbles(grumbles)
  local hadGrumbles = storage.grumbles and #storage.grumbles > 0

  storage.grumbles = grumbles
  if #grumbles > 0 then
    if not world.polyContains(storage.home.boundary, mcontroller.position()) then
      receiveNotification({ name = "returnHome" })
    elseif not hadGrumbles then
      receiveNotification({ name = "grumble" })
    end
    if emote then
      emote("sad")
    end
  end
end
