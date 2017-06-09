require "/scripts/vec2.lua"

function init()
  storage.spawnTime = storage.spawnTime or world.time()
  self.hatchTime = config.getParameter("hatchTime")
  self.forceHatchTime = config.getParameter("forceHatchTime")

  checkHatching()
end

function update()
  checkHatching()
end

function checkHatching()
  local age = world.time() - storage.spawnTime
  if age >= self.forceHatchTime then
    animator.playSound("hatch")
    hatch()
  elseif age >= self.hatchTime then
    storage.hatching = true
    animator.setAnimationState("egg", "wobble")
    object.setInteractive(true)
  else
    object.setInteractive(false)
  end
end

function onInteraction()
  if storage.hatching then
    animator.playSound("hatch")
    hatch()
  end
end

function hatch()
  animator.burstParticleEmitter("hatch")
  local parameters = config.getParameter("monsterParameters", {})
  parameters.level = 1
  world.spawnMonster(config.getParameter("spawnMonster"), vec2.add(entity.position(), config.getParameter("spawnOffset")), parameters)
  object.smash(true)
end
