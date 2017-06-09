function notify(notification)
  if notification.type == "missionStarted" then
    animator.setAnimationState("alarm", "on")
  elseif notification.type == "reinforcementsLeave" then
    animator.setAnimationState("alarm", "off")
    animator.playSound("off")
  end
end
