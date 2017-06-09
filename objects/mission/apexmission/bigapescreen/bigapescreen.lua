function init()
  message.setHandler("setState", function(_, _, state)
    animator.setAnimationState("screen", state)
  end)
end
