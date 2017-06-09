require "/scripts/rect.lua"
require "/scripts/vec2.lua"
require "/scripts/poly.lua"
require "/scripts/interp.lua"
require "/scripts/util.lua"

function init()
  self.fadeColorDuration = config.getParameter("fadeColorDuration")
  self.fadeColor = config.getParameter("fadeColor")
  self.borderColor = config.getParameter("borderColor")

  self.elapsed = 0
  effect.addStatModifierGroup({
    { stat = "invulnerable", amount = 1 }
  })
end

function update(dt)
  if self.elapsed < 0 then
    effect.expire()
    return
  end

  self.elapsed = math.min(self.fadeColorDuration, self.elapsed + dt)
  local fade = util.round(self.elapsed / self.fadeColorDuration, 1) * 0.6

  local fadeHex = string.format("%02x%02x%02x", self.fadeColor[1], self.fadeColor[2], self.fadeColor[3])
  local borderColor = string.format("%02x%02x%02x", self.borderColor[1], self.borderColor[2], self.borderColor[3])
  effect.setParentDirectives(string.format("?fade=%s;%.1f?border=3;%s%02x;%s00", fadeHex, fade, fadeHex, math.floor(fade * 255), borderColor))

  local intensity = math.floor(self.elapsed / self.fadeColorDuration * 225)
  animator.setLightColor("glow", {intensity, intensity, intensity})

  mcontroller.setVelocity({0, 0})
end

function uninit()
end
