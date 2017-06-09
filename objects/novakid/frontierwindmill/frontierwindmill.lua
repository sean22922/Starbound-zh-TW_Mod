require "/scripts/vec2.lua"

function init()
  self.rotationCenter = config.getParameter("wheelRotationCenter")
  self.rotationRate = -config.getParameter("wheelRotationRate") * object.direction()
  self.rotationDelta = config.getParameter("wheelRotationDelta")
  self.maxRotationRate = config.getParameter("wheelMaxRotationRate")
  self.rotationUpdateTime = config.getParameter("wheelRotationUpdateTime")

  self.windSensorPosition = vec2.add(object.position(), config.getParameter("windSensorPosition"))

  updateTargetRotationRate()
  self.currentRotationRate = self.targetRotationRate
  self.updateTimer = self.rotationUpdateTime
end

function update(dt)
  self.updateTimer = math.max(0, self.updateTimer - dt)
  if self.updateTimer == 0 then
    updateTargetRotationRate()
    self.updateTimer = self.rotationUpdateTime
  end

  if self.currentRotationRate < self.targetRotationRate then
    self.currentRotationRate = math.min(self.currentRotationRate + self.rotationDelta * dt, self.targetRotationRate)
  elseif self.currentRotationRate > self.targetRotationRate then
    self.currentRotationRate = math.max(self.currentRotationRate - self.rotationDelta * dt, self.targetRotationRate)
  end

  animator.rotateTransformationGroup("wheel", self.currentRotationRate * dt, self.rotationCenter)
end

function updateTargetRotationRate()
  self.targetRotationRate = self.rotationRate * world.windLevel(self.windSensorPosition)
  if math.abs(self.targetRotationRate) > self.maxRotationRate then
    if self.targetRotationRate < 0 then
      self.targetRotationRate = -self.maxRotationRate
    else
      self.targetRotationRate = self.maxRotationRate
    end
  end
end
