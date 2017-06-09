require "/scripts/vec2.lua"

function init()
  self.angle = mcontroller.rotation()
  local vector = vec2.rotate({1, 0}, self.angle + math.pi/2)
  status.setStatusProperty("ballisticVelocity", vec2.mul(vector, 100))
end

function update()
  mcontroller.setRotation(self.angle)
end

function uninit()
  status.addEphemeralEffect("ballistic")
end
