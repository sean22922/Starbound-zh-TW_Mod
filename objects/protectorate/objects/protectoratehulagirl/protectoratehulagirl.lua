function init()
  object.setInteractive(true)
  animator.setAnimationState("sway", "stop")
end

function onInteraction(args)
  animator.setAnimationState("sway", "sway1")
end
