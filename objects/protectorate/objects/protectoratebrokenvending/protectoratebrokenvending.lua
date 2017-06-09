function init()
  object.setInteractive(true)
end

function onInteraction(args)
  animator.burstParticleEmitter("sparks")
  animator.playSound("error")
end
