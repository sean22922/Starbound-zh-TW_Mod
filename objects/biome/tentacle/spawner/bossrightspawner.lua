require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  self.spawners = {}
  self.spawnerConfig = config.getParameter("spawnPoints")
  self.width = config.getParameter("objectWidth")
  self.monsters = {}

  message.setHandler("enableSpawner", function(arg1, arg2, spawnerName) enableSpawner(spawnerName) end)
  message.setHandler("reset", reset)
end

function update(dt)
  for _,spawn in pairs(self.spawners) do
    spawn(dt)
  end

  self.monsters = util.filter(self.monsters, world.entityExists)
end

function reset()
  self.spawners = {}
  for spawnerName,_ in pairs(self.spawnerConfig) do
    animator.setAnimationState(spawnerName, "idle")
  end
  for _,monsterId in pairs(self.monsters) do
    world.sendEntityMessage(monsterId, "despawn")
  end
end

function absolutePosition(offset, width) 
  if object.direction() > 0 then
    return vec2.add(entity.position(), offset)
  else
    return vec2.add(vec2.add(entity.position(), {width, 0}), {-offset[1], offset[2]})
  end
end

function enableSpawner(spawnerName)
  local spawner = self.spawnerConfig[spawnerName]
  local position = absolutePosition(spawner.offset, self.width)
  animator.setAnimationState(spawnerName, "pulse")

  local parameters = {
    aggressive = true,
    level = world.threatLevel(),
    behaviorConfig = {
      targetQueryRange = config.getParameter("monsterQueryRange"),
      keepTargetInSight = false,
      keepTargetInRange = 200
    }
  }

  local spawnFn = coroutine.wrap(function()
    local timer = math.random() * spawner.interval
    while true do
      timer = timer + script.updateDt()
      if timer >= spawner.interval then
        -- telegraph
        for i=1, 6 do
          util.wait(0.25)
          animator.burstParticleEmitter(spawnerName)
          animator.playSound("spawn")
        end

        -- spawn
        for i = 1, spawner.count or 1 do
          local monsterId = world.spawnMonster(spawner.monster, position, parameters)
          table.insert(self.monsters, monsterId)
        end
        animator.burstParticleEmitter(spawnerName)
        animator.playSound("spawn")

        -- reset
        timer = timer - spawner.interval
      end
      coroutine.yield()
    end
  end)

  self.spawners[spawnerName] = spawnFn
end
