function init()
  self.spawnedEntityId = nil

  self.state = stateMachine.create({
    "spawnState"
  })
  self.state.leavingState = function(stateName)
    animator.setAnimationState("movement", "idle")
  end

  animator.setAnimationState("movement", "idle")
  object.setInteractive(false)
end

function update(dt)
  if self.spawnedEntityId ~= nil and not world.entityExists(self.spawnedEntityId) then
    self.spawnedEntityId = nil
  end

  self.state.update(dt)
end

--------------------------------------------------------------------------------
spawnState = {}

function spawnState.enter()
  if self.spawnedEntityId ~= nil then return nil end

  return { timer = 0, spawned = false }
end

function spawnState.update(dt, stateData)
  local animation = animator.animationState("movement")
  if animation == "idle" then
    if stateData.spawned then
      return true, config.getParameter("spawnCooldownTime")
    else
      animator.setAnimationState("movement", "spawn")
    end
  elseif animation == "spawn" then
    stateData.timer = stateData.timer + dt

    if not stateData.spawned and stateData.timer > config.getParameter("spawnTime") then
      self.spawnedEntityId = world.spawnNpc(spawnState.spawnPosition(), "apex", "default", object.level())
      stateData.spawned = true
    end
  elseif animation == "idleOpen" then
    stateData.timer = stateData.timer + dt

    if stateData.timer > config.getParameter("closeTime") then
      animator.setAnimationState("movement", "close")
    end
  end

  return false
end

function spawnState.spawnPosition()
  return vec2.add(object.position(), config.getParameter("spawnOffset"))
end
