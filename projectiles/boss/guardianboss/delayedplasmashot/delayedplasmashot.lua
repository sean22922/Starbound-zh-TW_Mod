require "/scripts/util.lua"

function init()
  local players = world.entityQuery(entity.position(), 200, {includedTypes = {"player"}})
  players = util.filter(shuffled(players), function(entityId)
      return not world.lineTileCollision(entity.position(), world.entityPosition(entityId))
    end)
  self.target = players[1]
  if not self.target then projectile.die() end
end

function update()
  if not self.target or not world.entityExists(self.target) then return end

  local targetPosition = world.entityPosition(self.target)
  if targetPosition then
    local toTarget = world.distance(targetPosition, mcontroller.position())
    local angle = math.atan(toTarget[2], toTarget[1])
    mcontroller.setRotation(angle)
  end

  if projectile.sourceEntity() and not world.entityExists(projectile.sourceEntity()) then
    projectile.die()
  end
end

function destroy()
  if self.target and projectile.sourceEntity() and world.entityExists(projectile.sourceEntity()) then
    local rotation = mcontroller.rotation()
    world.spawnProjectile("plasmashot", mcontroller.position(), projectile.sourceEntity(), {math.cos(rotation), math.sin(rotation)}, false, { speed = 50, power = projectile.getParameter("power"), damageTeam = {type = "indiscriminate"}})
    projectile.processAction(projectile.getParameter("explosionAction"))
  end
end
