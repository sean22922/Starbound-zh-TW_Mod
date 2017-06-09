require "/scripts/status.lua"
require "/scripts/util.lua"

function init()
  local states = { "move", "attack" }
  self.state = stateMachine.create(states)

  self.spawnTimer = 1.5

  monster.setDeathParticleBurst("deathPoof")
  setAnimation("invisible", true)

  rangedAttack.loadConfig()
  
  if animator.hasSound("deathPuff") then
    monster.setDeathSound("deathPuff")
  end

  self.damageListener = damageListener("damageTaken", function(notifications) 
    if not self.targetId then
      self.targetId = notifications[1].sourceEntityId
    end
  end)
end

function isPenguinReinforcement()
  return true
end

function update(dt)
  self.damageListener:update()

  if self.spawnTimer ~= nil then
    self.spawnTimer = self.spawnTimer - dt
    mcontroller.controlFace(1)
    if self.spawnTimer < 0.5 then
      setAnimation("idle", true)
    end
    if self.spawnTimer <= 0 then
      self.spawnTimer = nil
    end
  else
    trackTarget()

    self.state.update(dt)
  end
end

function trackTarget()
  if not self.targetId or not world.entityExists(self.targetId) then
    self.targetId = util.closestValidTarget(25.0)
    if self.targetId == 0 then self.targetId = nil end
  end

  if self.targetId then
    self.targetPosition = world.entityPosition(self.targetId)
  else
    self.targetPosition = nil
  end
end

function shouldDie()
  if not status.resourcePositive("health") then
    local deathexplosion = config.getParameter("deathexplosion")
    if deathexplosion then
      world.spawnProjectile(deathexplosion.type, mcontroller.position(), entity.id(), {0, 1}, true, deathexplosion.config)
    end
    return true
  else
    return false
  end
end

function aimAt(targetPosition)
  local gunBaseOffset = config.getParameter("gunBaseOffset")
  gunBaseOffset[1] = -gunBaseOffset[1]
  local gunBasePosition = monster.toAbsolutePosition(gunBaseOffset)

  local gunBarrelOffset = config.getParameter("gunBarrelOffset")
  gunBarrelOffset[1] = -gunBarrelOffset[1]
  local gunBarrelPosition = monster.toAbsolutePosition(gunBarrelOffset)

  local toTarget = world.distance(targetPosition, gunBasePosition)
  mcontroller.controlFace(util.toDirection(toTarget[1]))

  local desiredAimAngle = vec2.angle({toTarget[1] * mcontroller.facingDirection(), toTarget[2]})
  animator.rotateGroup("weapon", -desiredAimAngle)
  animator.rotateGroup("arms", -desiredAimAngle)

  local aimAngle = -animator.currentRotationAngle("weapon")
  local gunBarrel = vec2.rotate(world.distance(gunBarrelPosition, gunBasePosition), aimAngle * mcontroller.facingDirection())

  gunBarrelPosition = vec2.add({ gunBasePosition[1], gunBasePosition[2] }, gunBarrel)
  gunBarrelOffset = world.distance(gunBarrelPosition, mcontroller.position())
  gunBarrelOffset[1] = gunBarrelOffset[1] * mcontroller.facingDirection()
  rangedAttack.aim(gunBarrelOffset, gunBarrel)

  -- Just put the empty hand down
  if config.getParameter("hasEmptyHand") then
    animator.rotateGroup("emptyHand", math.pi / 2.0)
  end

  return math.abs(desiredAimAngle - aimAngle) < 0.05
end

function targetInRange()
  if self.targetPosition == nil then return false end

  local distance = world.magnitude(world.distance(self.targetPosition, mcontroller.position()))
  return distance > 3.0 and distance < 15.0
end

function setAnimation(animationName, immediate)
  if immediate == nil then immediate = false end

  animator.setAnimationState("movement", animationName)

  -- Put the arms down and weapon in holstered position
  if animationName ~= "aim" then
    animator.rotateGroup("weapon", -math.pi / 2.0, immediate)
    animator.rotateGroup("arms", 0, immediate)
  end
end

--------------------------------------------------------------------------------
move = {}

move.enter = function()
  if self.targetPosition == nil or targetInRange() then
    return nil
  else
    setAnimation("walk")
    return {}
  end
end

move.update = function(dt, stateData)
  if not self.targetPosition then
    return false
  end

  local toTarget = world.distance(self.targetPosition, mcontroller.position())
  local distance = world.magnitude(toTarget)
  if distance < 4.0 then
    -- Back up
    mcontroller.controlFace(-toTarget[1])

    mcontroller.controlMove(toTarget[1], true)
  elseif distance > 14.0 then
    -- Move closer
    mcontroller.controlFace(toTarget[1])

    mcontroller.controlMove(toTarget[1], true)
  else
    mcontroller.controlFace(toTarget[1])
    setAnimation("idle")
    return true
  end

  return false
end

--------------------------------------------------------------------------------
attack = {}

attack.enter = function()
  if targetInRange() then
    setAnimation("aim")
    return {}
  else
    return nil
  end
end

attack.update = function(dt, stateData)
  if not targetInRange() then
    rangedAttack.stopFiring()
    setAnimation("idle")
    return true
  end

  if aimAt(self.targetPosition) then
    rangedAttack.fireContinuous()
  else
    rangedAttack.stopFiring()
  end

  return false
end
