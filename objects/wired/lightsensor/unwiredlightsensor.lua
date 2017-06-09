function init()
  self.detectThresholdHigh = config.getParameter("detectThresholdHigh")
  self.detectThresholdLow = config.getParameter("detectThresholdLow")
end

function getSample()
  local sample = world.lightLevel(object.position())
  return math.floor(sample * 1000) * 0.1
end

function update(dt)
  local sample = getSample()

  if sample >= self.detectThresholdLow then
    animator.setAnimationState("sensorState", "med")
  else
    animator.setAnimationState("sensorState", "min")
  end

  if sample >= self.detectThresholdHigh then
    animator.setAnimationState("sensorState", "max")
  else
    animator.setAnimationState("sensorState", "min")
  end
end
