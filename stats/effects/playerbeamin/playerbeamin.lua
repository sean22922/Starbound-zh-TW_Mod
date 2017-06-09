function init()
  effect.addStatModifierGroup({{stat = "invulnerable", amount = 1}})

  world.spawnProjectile("beamdownknockback", entity.position(), entity.id(), {0, 0}, false)
end

function update(dt)
end

function uninit()
end