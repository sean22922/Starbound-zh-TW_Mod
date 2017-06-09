function init()
  self.detectArea = config.getParameter("detectArea")
  self.detectArea[1] = object.toAbsolutePosition(self.detectArea[1])
  self.detectArea[2] = object.toAbsolutePosition(self.detectArea[2])

  animator.setAnimationState("proximity", "off")
end

function update(dt)
  local players = world.entityQuery(self.detectArea[1], self.detectArea[2], {
      includedTypes = {"player"},
      boundMode = "CollisionArea"
    })

  if #players > 0 and animator.animationState("proximity") == "off" then
    animator.setAnimationState("proximity", "open")
  elseif #players == 0 and animator.animationState("proximity") == "on" then
    animator.setAnimationState("proximity", "close")
  end
end

function onInteraction(args)
  local chatOptions = config.getParameter("chatOptions", {})
  if #chatOptions > 0 then
    object.say(chatOptions[math.random(1, #chatOptions)])
  end
end
