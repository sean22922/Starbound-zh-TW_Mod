require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/interp.lua"

function init()
  self.rotationOffset = util.toRadians(config.getParameter("rotationOffset"))
  self.partAngles = config.getParameter("partAngles")
  self.attackRotation = util.toRadians(config.getParameter("attackRotation"))
  self.attackTime = config.getParameter("attackTime")

  self.floorDebrisAngle = util.toRadians(config.getParameter("floorDebrisAngle"))
  self.damageAngle = util.toRadians(config.getParameter("damageAngle"))

  self.state = FSM:new()
  self.state:set(idle)

  message.setHandler("attack", function()
    self.state:set(attack)
  end)
end

function setRotation(angle)
  animator.resetTransformationGroup("tentacle")
  animator.rotateTransformationGroup("tentacle", self.rotationOffset + angle)

  for partName,partAngle in pairs(self.partAngles) do
    if math.abs(angle) >= util.toRadians(partAngle) then
      animator.setAnimationState(partName, "visible")
    else
      animator.setAnimationState(partName, "invisible")
    end
  end

  if math.abs(angle) > self.floorDebrisAngle then
    animator.setParticleEmitterActive("floordebris", true)
  else
    animator.setParticleEmitterActive("floordebris", false)
  end

  if math.abs(angle) > self.damageAngle then
    local ds = config.getParameter("damageConfig")
    ds.damage = ds.damage * root.evalFunction("monsterLevelPowerMultiplier", world.threatLevel())
    ds.knockback = vec2.mul(ds.knockback, {object.direction(), 1})
    ds.sourceEntityId = entity.id()

    object.setDamageSources({ds})
  else
    object.setDamageSources(nil)
  end
end

function update(dt)
  self.state:update()
end

function idle()
  while true do
    coroutine.yield()
  end
end

function attack()
  animator.setParticleEmitterActive("windup", true)
  animator.playSound("windupstart")
  animator.playSound("winduploop", -1)

  util.wait(4.0)

  animator.stopAllSounds("winduploop")
  animator.playSound("movestart")
  animator.playSound("moveloop", -1)

  local timer = 0
  util.wait(self.attackTime, function(dt)
    timer = math.min(timer + dt, self.attackTime)
    local angle = interp.sin(timer / self.attackTime, 0, self.attackRotation)
    setRotation(angle)
  end)
  animator.setParticleEmitterActive("floordebris", false)
  animator.setParticleEmitterActive("windup", false)

  animator.stopAllSounds("moveloop")

  util.wait(1.0)

  animator.playSound("movestart")
  animator.playSound("moveloop", -1)
  
  animator.setParticleEmitterActive("windup", true)
  timer = 0
  util.wait(self.attackTime, function(dt)
    timer = math.min(timer + dt, self.attackTime)
    local angle = interp.reverse(interp.sin)(timer / self.attackTime, 0, self.attackRotation)
    setRotation(angle)
  end)

  setRotation(0)
  animator.setParticleEmitterActive("windup", false)
  animator.stopAllSounds("moveloop")
  util.wait(1.0)

  self.state:set(idle)
end
