function init()
  object.setInteractive(true)
  
  output(false)
end

function onInteraction(args)
  output(not storage.state)
end

function output(state)
  storage.state = state
  if state then
    animator.setAnimationState("state", "on")
    object.setSoundEffectEnabled(true)
    animator.playSound("on")
  else
    animator.setAnimationState("state", "off")
    object.setSoundEffectEnabled(false)
    animator.playSound("off")
  end
end
