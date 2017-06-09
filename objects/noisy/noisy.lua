function init()
  self.sounds = config.getParameter("sounds", {})
  animator.setSoundPool("noise", self.sounds)
  object.setInteractive(true)
end

function onInteraction()
  if #self.sounds > 0 then
    animator.playSound("noise")
  end
end

function onNpcPlay(npcId)
  local interact = config.getParameter("npcToy.interactOnNpcPlayStart")
  if interact == nil or interact ~= false then
    onInteraction()
  end
end
