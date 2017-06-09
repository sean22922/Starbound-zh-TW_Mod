require "/scripts/util.lua"

function init()
  local angle = util.toRadians(util.randomInRange(config.getParameter("angleRange", {-30, 30})))
  animator.rotateTransformationGroup("signal", angle)
  animator.translateTransformationGroup("signal", {0, -0.5})

  self.blinkLength = config.getParameter("blinkLength", 0.5)

  local interval = util.randomInRange(config.getParameter("blinkInterval", 1.0))
  self.blink = util.interval(interval, function()
    animator.setAnimationState("blink", "lit")
    animator.burstParticleEmitter("signal")
    animator.setLightActive("blink", true)

    self.blinkTimer = self.blinkLength
  end)
end

function update(dt)
  self.blink(dt)

  if self.blinkTimer then
    self.blinkTimer = math.max(self.blinkTimer - dt, 0)
    if self.blinkTimer == 0 then
      animator.setLightActive("blink", false)
      animator.setAnimationState("blink", "idle")
      animator.burstParticleEmitter("signal2")
      
      self.blinkTimer = nil
    end
  end
end
