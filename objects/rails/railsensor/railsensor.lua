require "/scripts/util.lua"

function init()
  self.detectDuration = config.getParameter("detectDuration", 1.0)

  message.setHandler("railRiderPresent", function()
    setActive(self.detectDuration)
  end)

  setActive(storage.active or 0)
end

function update(dt)
  setActive(math.max(0, storage.active - dt))
end

function setActive(activeTime)
  if activeTime > 0 and storage.active == 0 then
    animator.playSound("detect")
  end
  storage.active = activeTime
  animator.setAnimationState("sensor", storage.active > 0 and "on" or "off")
  object.setOutputNodeLevel(0, storage.active > 0)
end
