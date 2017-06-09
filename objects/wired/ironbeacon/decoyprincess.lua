function goodReception()
  if world.underground(object.position()) then
    return false
  end

  local ll = object.toAbsolutePosition({ -4.0, 1.0 })
  local tr = object.toAbsolutePosition({ 4.0, 32.0 })

  local bounds = {0, 0, 0, 0}
  bounds[1] = ll[1]
  bounds[2] = ll[2]
  bounds[3] = tr[1]
  bounds[4] = tr[2]

  return not world.rectTileCollision(bounds, {"Null", "Block", "Dynamic", "Slippery"})
end

function init()
  object.setInteractive(true)
end

function onInteraction(args)
  if not goodReception() then
    return { "ShowPopup", { message = "I should take it to the planet surface and see what it attracts." } }
  else
    object.smash()
    world.spawnProjectile("regularexplosionknockback", object.toAbsolutePosition({ 0.0, 1.0 }))
    world.spawnMonster("dragonboss", object.toAbsolutePosition({ 0.0, 30.0 }), { level = 3 })
  end
end

function hasCapability(capability)
  return false
end
