require "/scripts/rect.lua"
require "/scripts/vec2.lua"
require "/scripts/poly.lua"
require "/scripts/interp.lua"
require "/scripts/util.lua"

function init()
  self.fadeColorDuration = config.getParameter("fadeColorDuration")
  self.fadeColor = config.getParameter("fadeColor")
  self.shrinkDuration = config.getParameter("shrinkDuration")

  local bounds = mcontroller.boundBox()
  local size = rect.size(bounds)
  local shrinkSize = config.getParameter("shrinkSize")
  self.shrinkRatio = shrinkSize / math.max(size[1], size[2])

  self.elapsed = 0
  self.grow = config.getParameter("grow", false)
  if self.grow then
    self.elapsed = self.fadeColorDuration + self.shrinkDuration
  end

  effect.addStatModifierGroup({
    { stat = "invulnerable", amount = 1 }
  })
end

function update(dt)
  if self.grow then
    self.elapsed = self.elapsed - dt
  else
    self.elapsed = self.elapsed + dt
  end

  if self.elapsed < 0 then
    effect.expire()
    return
  end

  local toColor = copy(self.fadeColor)
  local fade = 1.0
  local scale = 1.0
  if self.elapsed < self.fadeColorDuration then
    fade = self.elapsed / self.fadeColorDuration
  elseif self.elapsed < (self.fadeColorDuration + self.shrinkDuration) then
    local ratio = (self.elapsed - self.fadeColorDuration) / self.shrinkDuration
    toColor = util.zipWith(toColor, {255, 255, 255}, function(a,b) return math.floor(interp.linear(ratio, a, b)) end)
    scale = interp.linear(ratio, 1.0, self.shrinkRatio)
  else
    toColor = {255, 255, 255, 255}
    scale = self.shrinkRatio
  end

  local fadeHex = string.format("%02x%02x%02x", toColor[1], toColor[2], toColor[3])
  local borderColor = string.format("%02x%02x%02x", self.fadeColor[1], self.fadeColor[2], self.fadeColor[3])
  effect.setParentDirectives(string.format("?fade=%s;%.1f?scalenearest=%.2f?border=3;%s%02x;%s00", fadeHex, fade, scale, borderColor, math.floor(fade * 255), borderColor))

  mcontroller.setVelocity({0, 0})
end

function uninit()
end
