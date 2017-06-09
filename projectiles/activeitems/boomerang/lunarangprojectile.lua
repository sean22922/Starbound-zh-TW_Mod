require "/scripts/vec2.lua"

boomerangExtra = {}

function boomerangExtra:init()
  self.shardCount = config.getParameter("shardCount", 1)
  self.shardType = config.getParameter("shardType")

  self.hasCollided = false
end

function boomerangExtra:update(dt)
  if not self.hasCollided and mcontroller.isColliding() then
    self.hasCollided = true
    self.shardIds = {}
    local params = {}
    params.powerMultiplier = config.getParameter("powerMultiplier", 1.0)
    params.power = config.getParameter("power") / self.shardCount
    params.returning = true
    local baseAngle = math.random() * math.pi * 2
    local iterateAngle = (math.pi * 2) / self.shardCount
    for i = 1, self.shardCount do
      local shardId = world.spawnProjectile(
          self.shardType,
          mcontroller.position(),
          projectile.sourceEntity(),
          vec2.withAngle(baseAngle + i * iterateAngle),
          false,
          params
        )
      if shardId then
        table.insert(self.shardIds, shardId)
      end
    end
  end
end

function boomerangExtra:projectileIds()
  if self.hasCollided then
    projectile.die()
    return self.shardIds
  else
    return {entity.id()}
  end
end
