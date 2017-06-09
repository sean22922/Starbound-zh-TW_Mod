function init()
  self.timers = {}
  for i = 1, 4 do
    self.timers[i] = math.random() * 2 * math.pi
  end

  script.setUpdateDelta(3)
end

function update(dt)
  for i = 1, 4 do
    self.timers[i] = self.timers[i] + dt
    if self.timers[i] > (2 * math.pi) then self.timers[i] = self.timers[i] - 2 * math.pi end

    local lightAngle = math.cos(self.timers[i]) * 120 + (i * 90)
    animator.setLightPointAngle("light"..i, lightAngle)
  end
end

function uninit()
  
end
