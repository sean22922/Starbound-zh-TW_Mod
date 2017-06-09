require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/drops.lua"
require "/scripts/status.lua"
require "/scripts/actions/crawling.lua"

-- Engine callback - called on initialization of entity
function init()
  self.shouldDie = true

  if animator.hasSound("deathPuff") then
    monster.setDeathSound("deathPuff")
  end
  if config.getParameter("deathParticles") then
    monster.setDeathParticleBurst(config.getParameter("deathParticles"))
  end

  script.setUpdateDelta(5)

  self.outOfSight = {}
  self.targets = {}
  self.queryRange = config.getParameter("queryRange", 50)
  self.keepTargetInRange = config.getParameter("keepTargetInRange", 200)

  -- Listen to damage taken for getting stunned and suppressing damage
  self.damageTaken = damageListener("damageTaken", function(notifications)
    for _,notification in pairs(notifications) do
      if notification.healthLost > 0 then
        if not contains(self.targets, notification.sourceEntityId) then
          table.insert(self.targets, notification.sourceEntityId)
        end
        self.damaged = true
      end
    end
  end)

  self.state = FSM:new()
  self.state:set(idleState)

  self.wanderBurnForce = 10
  self.facingDirection = 1.0
  self.startPosition = mcontroller.position()
  self.angularVelocity = 0.0
  self.angle = 0.0
end

function update(dt)
  self.damageTaken:update()

  if status.resourcePositive("stunned") then
    animator.setAnimationState("damage", "stunned")
    mcontroller.clearControls()
    if self.damaged then
      self.suppressDamageTimer = config.getParameter("stunDamageSuppression", 0.5)
      monster.setDamageOnTouch(false)
    end
    return
  else
    animator.setAnimationState("damage", "none")
  end

  -- Suppressing touch damage
  if self.suppressDamageTimer then
    monster.setDamageOnTouch(false)
    self.suppressDamageTimer = math.max(self.suppressDamageTimer - dt, 0)
    if self.suppressDamageTimer == 0 then
      self.suppressDamageTimer = nil
    end
  elseif status.statPositive("invulnerable") then
    monster.setDamageOnTouch(false)
  else
    monster.setDamageOnTouch(true)
  end

  -- query for new targets if there are none
  if #self.targets == 0 then
    local newTargets = world.entityQuery(mcontroller.position(), self.queryRange, {includedTypes = {"player"}})
    table.sort(newTargets, function(a, b)
      return world.magnitude(world.entityPosition(a), mcontroller.position()) < world.magnitude(world.entityPosition(b), mcontroller.position())
    end)
    for _,entityId in pairs(newTargets) do
      if entity.entityInSight(entityId) then
        table.insert(self.targets, entityId)
      end
    end
  end

  -- drop targets out of range, keep current target the top of the targets list
  repeat
    self.target = self.targets[1]
    if self.target == nil then break end

    local target = self.target
    if not world.entityExists(target)
       or world.magnitude(world.entityPosition(target), mcontroller.position()) > self.keepTargetInRange then
      table.remove(self.targets, 1)
      self.target = nil
    end

    if self.target and not entity.entityInSight(target) then
      local timer = self.outOfSight[target] or 3.0
      timer = timer - dt
      if timer <= 0 then
        table.remove(self.targets, 1)
        selftarget = nil
      else
        self.outOfSight[target] = timer
      end
    end

    if not self.target then
      self.outOfSight[target] = nil
    end
  until #self.targets <= 0 or self.target

  monster.setAggressive(self.target ~= nil)
  monster.setDamageOnTouch(self.target ~= nil)

  -- update state
  mcontroller.controlFace(1)
  self.state:update()

  self.angle = self.angle + self.facingDirection * self.angularVelocity
  animator.resetTransformationGroup("body")
  animator.rotateTransformationGroup("body", self.angle)
  animator.resetTransformationGroup("facing")
  animator.scaleTransformationGroup("facing", {self.facingDirection, 1.0})
end

-- burns up and adds angular velocity
function burn(force)
  self.angularVelocity = util.clamp(self.angularVelocity - 0.1 * script.updateDt(), -0.15, 0.15)
  -- burn up
  local burnAngle = (math.pi / 2) + self.angle
  mcontroller.controlApproachVelocity(vec2.withAngle(burnAngle, mcontroller.baseParameters().flySpeed), force or mcontroller.baseParameters().airForce)
end

function idleState()
  self.facingDirection = util.randomDirection()

  util.wait(2.0 + math.random() * 4.0, function()
    local toGround = findGroundDirection(1.0)
    if toGround then
      animator.setAnimationState("body", "ground")

      self.startPosition = mcontroller.position()
      self.angularVelocity = 0
      local headingAngle = (vec2.angle(toGround) + math.pi / 2) % (math.pi * 2)
      self.angle = adjustCornerHeading(headingAngle, mcontroller.facingDirection())

      mcontroller.controlApproachVelocity(vec2.mul(vec2.withAngle(self.angle - math.pi / 2), mcontroller.baseParameters().flySpeed), mcontroller.baseParameters().groundForce)
      mcontroller.controlApproachVelocityAlongAngle(self.angle, 0, mcontroller.baseParameters().groundForce)

      animator.resetTransformationGroup("body")
      animator.rotateTransformationGroup("body", self.angle)
    else
      animator.setAnimationState("body", "idle")
      mcontroller.controlApproachVelocity(vec2.mul(vec2.norm(mcontroller.velocity()), math.min(vec2.mag(mcontroller.velocity()), 4)), mcontroller.baseParameters().airForce)
    end
    coroutine.yield()
  end)

  if self.target then
    return self.state:set(attackState, true)
  else
    return self.state:set(wanderState)
  end
end

function attackState(initialBurn)
  -- burn up
  if initialBurn then
    util.wait(0.5, function()
      animator.setAnimationState("body", "fly")
      burn(self.wanderBurnForce)
    end)
  end

  while self.target and world.entityExists(self.target) do
    local angle = vec2.angle(world.distance(world.entityPosition(self.target), mcontroller.position()))
    if math.abs(util.angleDiff(self.angle + math.pi / 2, angle)) < 0.75 then
      burn()
      animator.setAnimationState("body", "fly")
    else
      animator.setAnimationState("body", "idle")
    end

    if findGroundDirection() then
      return self.state:set(idleState)
    end
    coroutine.yield()
  end

  return self.state:set(returnState)
end

function returnState()
  while not findGroundDirection() do
    local angle = vec2.angle(world.distance(self.startPosition, mcontroller.position()))
    if math.abs(util.angleDiff(self.angle + math.pi / 2, angle)) < 0.75 then
      burn()
      animator.setAnimationState("body", "fly")
    else
      animator.setAnimationState("body", "idle")
    end
    coroutine.yield()
  end

  return self.state:set(idleState)
end

function wanderState()
  -- burn up
  animator.setAnimationState("body", "fly")
  util.wait(0.5, function()
    burn(self.wanderBurnForce)
  end)
  animator.setAnimationState("body", "idle")


  local wander = coroutine.create(function()

    -- burning it sideways
    local burning, burned
    local angle = vec2.angle(world.distance(self.startPosition, mcontroller.position())) + util.randomDirection() * math.pi / 2
    while burning or not burned do
      if math.abs(util.angleDiff(self.angle + math.pi / 2, angle)) < 0.75 then
        burning = true
        burn(self.wanderBurnForce)
        animator.setAnimationState("body", "fly")
      else
        animator.setAnimationState("body", "idle")
        if burning then
          burned = true
        end
        burning = false
      end
      coroutine.yield()
    end

    -- burn back toward start until hitting the ground
    while not findGroundDirection() do
      angle = vec2.angle(world.distance(self.startPosition, mcontroller.position()))
      if math.abs(util.angleDiff(self.angle + math.pi / 2, angle)) < 0.75 then
        burn(self.wanderBurnForce)
        animator.setAnimationState("body", "fly")
      else
        animator.setAnimationState("body", "idle")
      end
      coroutine.yield()
    end
  end)

  local abort = function()
    -- abort wandering on finding a target
    if self.target then
      return self.state:set(attackState, false)
    elseif findGroundDirection(0.25) then
       return self.state:set(idleState)
    end
  end

  while util.parallel(wander, abort) do
    coroutine.yield()
  end

  return self.state:set(idleState)
end


function shouldDie()
  return self.shouldDie and status.resource("health") <= 0
end

function die()
  world.spawnProjectile("mechenergypickup", mcontroller.position())
  spawnDrops()
end

function uninit()
end
