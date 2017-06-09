function init()
  self.managerUid = config.getParameter("managerUid")
  object.setInteractive(true)
end

function onInteraction()
  if self.managerUid then
    world.sendEntityMessage(self.managerUid, "interact")
    animator.playSound("trigger")
  end
end
