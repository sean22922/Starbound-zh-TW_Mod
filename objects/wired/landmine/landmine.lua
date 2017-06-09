function init()
  object.setInteractive(true)
  object.setAllOutputNodes(false)
  animator.setAnimationState("switchState", "off")
  self.triggerTimer = 0

  local detectArea = config.getParameter("detectArea")
  local pos = entity.position()
  self.detectArea = {
    {pos[1] + detectArea[1][1], pos[2] + detectArea[1][2]},
    {pos[1] + detectArea[2][1], pos[2] + detectArea[2][2]}
  }
end

function trigger()
  object.setAllOutputNodes(true)
  animator.setAnimationState("switchState", "on")
  animator.playSound("on")
  if config.getParameter("firstProjectile") ~= nil then
    world.spawnProjectile(config.getParameter("firstProjectile"), object.toAbsolutePosition({ 0.0, 0.2 }))
  end
  self.triggerTimer = config.getParameter("triggerDelay")
end

function onInteraction(args)
  trigger()
end

function update(dt)
  if self.triggerTimer > 0 then
    self.triggerTimer = math.max(0, self.triggerTimer - dt)
    if self.triggerTimer == 0 then
      if config.getParameter("secondProjectile") ~= nil then
        world.spawnProjectile(config.getParameter("secondProjectile"), object.toAbsolutePosition({ 0.0, 0.2 }))
      end
      object.smash()
    end
  else
    local radius = config.getParameter("detectRadius")
    local entityIds = world.entityQuery(self.detectArea[1], self.detectArea[2], { includedTypes = {"creature"}, boundMode = "CollisionArea" })
    if #entityIds > 0 then
      trigger()
    end
  end
end
