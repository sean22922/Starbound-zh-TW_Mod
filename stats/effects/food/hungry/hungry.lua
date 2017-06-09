function init()
  world.sendEntityMessage(entity.id(), "queueRadioMessage", "hungry")

  self.soundInterval = config.getParameter("soundInterval")
  self.soundTimer = 0

  self.movementModifiers = config.getParameter("movementModifiers", {})
end

function update(dt)
  self.soundTimer = math.max(0, self.soundTimer - dt)
  if self.soundTimer == 0 then
    animator.playSound("beep")
    self.soundTimer = self.soundInterval
  end

  mcontroller.controlModifiers(self.movementModifiers)
end

function uninit()

end
