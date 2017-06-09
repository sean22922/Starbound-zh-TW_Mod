function init()
  self.fireTimer = 0
  self.chargeTime = 0.5

  object.setInteractive(true)

  storage.missionComplete = storage.missionComplete or false
  object.setOutputNodeLevel(1, storage.missionComplete)

  self.maxSwitches = 4
end

function onInputNodeChange(args)
  local activeNodes = activeInboundNodes()
  if args.level and activeNodes < self.maxSwitches then
    animator.playSound("blip")
  elseif args.level then
    animator.playSound("activate")
  end
end

function onInteraction()
  local activeNodes = activeInboundNodes()
  if activeNodes >= self.maxSwitches then
    self.fireTimer = self.chargeTime
  else
    animator.playSound("error")
  end
end

function update(dt)
  local activeNodes = activeInboundNodes()
  if self.fireTimer > 0 and activeNodes == self.maxSwitches then
    if self.fireTimer == self.chargeTime then
      animator.playSound("charge")
    end
    animator.setAnimationState("laserState", "on")
    self.fireTimer = self.fireTimer - dt

    if self.fireTimer < 0 then
      object.setOutputNodeLevel(0, true)
      local power = config.getParameter("projectilePower")
      local projectile = config.getParameter("projectileType")
      local offset = config.getParameter("projectileOffset")
      world.spawnProjectile(projectile, object.toAbsolutePosition(offset), entity.id(), {0, 1}, true, {power = power, damageType = "IgnoresDef"})
      animator.playSound("fire")
    end
  else
    object.setOutputNodeLevel(0, false)
    self.fireTimer = 0

    if activeNodes < self.maxSwitches then
      animator.setAnimationState("laserState", "off."..activeNodes)
    else
      animator.setAnimationState("laserState", "charged")
    end
  end
end

function activeInboundNodes()
  local activeNodes = 0
  for i = 0, self.maxSwitches - 1 do
    if object.getInputNodeLevel(i) then
      activeNodes = activeNodes + 1
    end
  end
  return activeNodes
end

function openLunarBaseDoor()
  storage.missionComplete = true
  object.setOutputNodeLevel(1, true)
end
