require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  message.setHandler("despawn", despawn)

  monster.setDeathParticleBurst("deathPoof")
  monster.setDeathSound("deathPuff")

  self.state = FSM:new()

  self.managerUid = config.getParameter("managerUid")
  self.bossId = config.getParameter("bossId")
  self.triggerId = config.getParameter("triggerId")
  message.setHandler("setGroup", function(_,_, entityIds)
    self.group = entityIds
  end)

  if config.getParameter("partOfGroup", false) then
    self.state:set(blorbState)
  else
    self.state:set(spawnState)
  end

  self.forceRegions = config.getParameter("forceRegions")

  monster.setDamageOnTouch(false)
end

function update(dt)
  if self.bossId and not world.entityExists(self.bossId) then
    self.state:set(despawnState)
    self.bossId = nil
  end

  local regions = {}
  for _,region in pairs(self.forceRegions) do
    region.center = entity.position()
    table.insert(regions, region)
  end
  monster.setPhysicsForces(regions)

  self.state:update()
end

function despawn()
  monster.setDropPool(nil)
  monster.setDeathParticleBurst(nil)
  monster.setDeathSound(nil)
  monster.setAnimationParameter("targetId", nil)
  status.addEphemeralEffect("monsterdespawn")
end

function die()
  if self.group then
    for _,entityId in pairs(self.group) do
      world.sendEntityMessage(entityId, "despawn")
    end
  end
end

-- States

function blorbState()
  while self.group == nil do
    status.addEphemeralEffect("invulnerable", 1.0)
    coroutine.yield()
  end
  self.state:set(spawnState)
end

function spawnState()
  status.addEphemeralEffect("invulnerable", 2)
  monster.setDamageOnTouch(false)

  animator.setAnimationState("body", "spawn")
  while animator.animationState("body") == "spawn" do
    coroutine.yield()
  end

  status.removeEphemeralEffect("invulnerable")
  self.state:set(waitForTargetState)
end

function waitForTargetState()
  local timer = 1.0
  while timer > 0 do
    if self.group then
      for _,entityId in pairs(self.group) do
        if entityId ~= entity.id() then
          monster.setAnimationParameter("targetId", entityId)
          self.state:set(idleState, entityId)
        end
      end
    end
    timer = timer + script.updateDt()
    coroutine.yield()
  end

  self.state:set(despawnState)
end

function idleState(targetId)
  while world.entityExists(targetId) do
    local targetPosition = world.entityPosition(targetId)
    world.debugLine(entity.position(), targetPosition, "yellow")
    if world.magnitude(targetPosition, entity.position()) < 1.0 then
      world.sendEntityMessage(targetId, "despawn")
      world.sendEntityMessage(targetId, "collide", entity.position())

      self.state:set(collideState)
    end
    coroutine.yield()
  end

  self.state:set(despawnState)
end

function despawnState()
  despawn()
  -- wait to despawn
  while true do coroutine.yield() end
end

function collideState()
  animator.setAnimationState("body", "despawn")

  monster.setDropPool(nil)
  monster.setDeathParticleBurst(nil)
  monster.setDeathSound(nil)

  util.wait(0.5)

  if self.triggerId then
    world.sendEntityMessage(self.managerUid, "trigger", self.triggerId, mcontroller.position())
  end

  status.setResource("health", 0)
  self.shouldDie = true
end
