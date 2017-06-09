require "/scripts/vec2.lua"

function init()
  self.delayTimer = config.getParameter("delayTime")
end

function update(dt)
  if self.delayTimer then
    self.delayTimer = math.max(0, self.delayTimer - dt)
    if self.delayTimer == 0 then
      self.delayTimer = nil
      trigger()
    end
  end
end

function trigger()
  mcontroller.setVelocity(vec2.mul(vec2.norm(mcontroller.velocity()), config.getParameter("triggerSpeed")))
end
