require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  self.power = config.getParameter("fistPower", 10)

  animator.setGlobalTag("directives", config.getParameter("directives", ""))

  message.setHandler("launchFist", function(_, _, group, power)
    local launcherGroups = config.getParameter("launcherGroups", {})
    if contains(launcherGroups, group) then
      self.launch = coroutine.wrap(launchFist)
      self.power = power
    end
  end)
end

function update(dt)
  if self.launch and self.launch() then 
    self.launch = nil
  end
end

function testLaunch()
  self.launch = coroutine.wrap(launchFist) 
end

function launchFist()
  animator.setAnimationState("launcher", "windup")

  util.wait(config.getParameter("windupTime", 1.0))

  animator.playSound("fire")
  animator.burstParticleEmitter("fire")
  local offset = config.getParameter("fistOffset", {0,0})
  local ttl = config.getParameter("fistTimeToLive")
  world.spawnProjectile("energyfist", vec2.add(entity.position(), offset), entity.id(), config.getParameter("fistVector", {0,1}), false, {power = self.power, timeToLive = ttl})

  util.wait(config.getParameter("fireTime", 0.5))

  animator.setAnimationState("launcher", "winddown")
  return true
end
