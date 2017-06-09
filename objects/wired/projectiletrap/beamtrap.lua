require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/poly.lua"
require "/scripts/rect.lua"

function init()
  self.beamDirection = vec2.norm(config.getParameter("beamDirection", {1, 0}))
  self.maxLength = config.getParameter("maxBeamLength", 50)
  self.startOffset = config.getParameter("beamStartOffset")
  self.startPosition = vec2.add(self.startOffset, entity.position())

  if storage.active == nil then
    storage.active = false
  end

  findEnd()

  animator.setAnimationState("trapState", "off")
  object.setSoundEffectEnabled(false)
  object.setLightColor(config.getParameter("inactiveLightColor", {0, 0, 0, 0}))
  object.setAnimationParameter("beams", {})

  script.setUpdateDelta(5)

  self.state = FSM:new()
  self.state:set(offState)
end

function update()
  findEnd()

  storage.active = (not object.isInputNodeConnected(0)) or object.getInputNodeLevel(0)

  self.state:update()
end

function projectileStart()
  local bounds = {0, 0, 0, 0}
  for _,space in pairs(object.spaces()) do
    bounds = {
      math.min(bounds[1], space[1]),
      math.min(bounds[2], space[2]),
      math.max(bounds[3], space[1] + 1),
      math.max(bounds[4], space[2] +1)
    }
  end
  return rect.snap(bounds, self.startOffset, self.beamDirection) 
end

function findEnd()
  self.endPosition = vec2.add(self.startPosition, vec2.mul(self.beamDirection, self.maxLength))
  local lineStart = vec2.add(self.startPosition, vec2.mul(self.beamDirection, 1.5))
  self.endPosition = world.lineCollision(lineStart, self.endPosition) or self.endPosition
end

function setBeamDamage(startProjectile, endProjectile)
  local beamStart = self.startPosition
  if startProjectile then
    beamStart = world.entityPosition(startProjectile) or beamStart
  end
  local beamEnd = self.endPosition
  if endProjectile then
    beamEnd = world.entityPosition(endProjectile) or beamEnd
  end

  local length = world.magnitude(beamEnd, beamStart)
  local angle = vec2.angle(world.distance(beamEnd, beamStart))
  local damagePoly = {{0, -0.5}, {0, 0.5}, {length, 0.5}, {length, -0.5}}
  damagePoly = poly.translate(poly.rotate(damagePoly, angle), beamStart)

  local damageSource = config.getParameter("beamDamage")
  damageSource.poly = poly.translate(damagePoly, vec2.mul(entity.position(), -1))
  if damageSource.knockback and type(damageSource.knockback) == "table" then
    damageSource.knockback = vec2.mul(damageSource.knockback, {object.direction(), 1})
  end
  object.setDamageSources({damageSource})

  object.setAnimationParameter("beams", {
    {
      startPosition = self.startPosition,
      endPosition = self.endPosition,
      startProjectile = startProjectile,
      endProjectile = endProjectile
    }  
  })
end

function setActive(active)
  if active then
    animator.setAnimationState("trapState", "on")
    object.setSoundEffectEnabled(true)
    animator.playSound("on")
    object.setLightColor(config.getParameter("activeLightColor", {0, 0, 0, 0}))
  else
    animator.setAnimationState("trapState", "off")
    object.setSoundEffectEnabled(false)
    animator.playSound("off")
    object.setLightColor(config.getParameter("inactiveLightColor", {0, 0, 0, 0}))
  end
end

function offState()
  object.setDamageSources({})
  object.setAnimationParameter("beams", {})

  while not storage.active do
    coroutine.yield()
  end

  self.state:set(startState)
end

function startState()
  setActive(true)
  object.setAnimationParameter("requireProjectile", false)

  local projectileOffset = projectileStart()
  local speed = config.getParameter("beamSpeed", 40)
  local length = world.magnitude(self.endPosition, vec2.add(entity.position(), projectileOffset))
  local params = {
    physics = "laser",
    speed = speed,
    timeToLive = length / speed,
    onlyHitTerrain = true
  }
  self.endProjectile = world.spawnProjectile("invisibleprojectile", vec2.add(entity.position(), projectileOffset), entity.id(), self.beamDirection, false, params)
  while world.entityExists(self.endProjectile) and storage.active do
    setBeamDamage(nil, self.endProjectile)
    coroutine.yield()
  end

  if not world.entityExists(self.endProjectile) then
    self.endProjectile = nil
  end

  self.state:set(onState)
end

function onState()
  while storage.active do
    setBeamDamage(nil, nil)
    coroutine.yield()
  end

  self.state:set(stopState)
end

function stopState()
  setActive(false)
  object.setAnimationParameter("requireProjectile", true)

  local projectileOffset = projectileStart()
  local speed = config.getParameter("beamSpeed", 40)
  local length = world.magnitude(self.endPosition, vec2.add(entity.position(), projectileOffset))
  local params = {
    physics = "laser",
    speed = speed,
    timeToLive = length / speed,
    onlyHitTerrain = true
  }
  self.startProjectile = world.spawnProjectile("invisibleprojectile", vec2.add(entity.position(), projectileOffset), entity.id(), self.beamDirection, false, params)
  while world.entityExists(self.startProjectile) do
    setBeamDamage(self.startProjectile, self.endProjectile)
    coroutine.yield()
  end

  if not world.entityExists(self.startProjectile) then
    self.startProjectile = nil
  end

  self.state:set(offState)
end