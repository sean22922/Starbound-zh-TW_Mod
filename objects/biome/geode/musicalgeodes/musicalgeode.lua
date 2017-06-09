function init()
  self.detectRadius = config.getParameter("radius", 3.0)
  self.chimePitch = config.getParameter("pitchMultiplier", 1.0)

  animator.setSoundPitch("chime", self.chimePitch, 0.0)

  self.loopSound = config.getParameter("looping", false)
  self.triggered = false
end

function update(dt)
  local players = world.entityQuery(object.position(), self.detectRadius, {
      includedTypes = {"player"},
      boundMode = "CollisionArea"
    })

  if #players > 0 then
    -- world.debugText("detected", object.position(), "green")
    if not self.triggered then
      chime()
      self.triggered = true
    end
  else
    if self.triggered then
      stopChime()
      self.triggered = false
    end
  end
end

function uninit()
  stopChime()
end

function chime()
  if self.loopSound then
    animator.playSound("chime", -1)
    animator.setAnimationState("geode", "loopchime")
  else
    animator.playSound("chime")
    animator.setAnimationState("geode", "chime")
  end
end

function stopChime()
  if self.loopSound then
    animator.stopAllSounds("chime", 0.66)
    animator.setAnimationState("geode", "silent")
  end
end
