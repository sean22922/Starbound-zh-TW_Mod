require "/scripts/util.lua"

function init()

end

function update(dt)
  local players = world.entityQuery(mcontroller.position(), 5, {
    includedTypes = { "player" },
    boundMode = "Position"
  })

  if #players > 0 then
    status.setResource("health", 0)
  end

  mcontroller.controlFace(1)
end

function die()
  world.spawnItem("petball", mcontroller.position(), 1)
end

function punt(direction)
  local angle = util.randomInRange(config.getParameter("angleRange"))
  local speed = util.randomInRange(config.getParameter("speedRange"))
  local puntVector = vec2.mul({direction * math.cos(angle), math.sin(angle)}, speed)
  mcontroller.setVelocity(puntVector)
end
