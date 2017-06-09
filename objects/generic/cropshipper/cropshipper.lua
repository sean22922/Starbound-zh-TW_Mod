require "/scripts/vec2.lua"
require "/scripts/rect.lua"

function init()
  self.surfaceCheckArea = rect.translate(config.getParameter("surfaceCheckArea"), entity.position())
  self.surfaceCheckInterval = config.getParameter("surfaceCheckInterval")
  self.surfaceCheckTimer = self.surfaceCheckInterval

  self.launchDuration = config.getParameter("launchDuration")
  self.launchTiming = config.getParameter("launchTiming")
  self.launchPosition = vec2.add(config.getParameter("launchPosition"), entity.position())

  self.onSurface = surfaceCheck()
  if self.onSurface then
    animator.setAnimationState("shipper", "ready")
  else
    animator.setAnimationState("shipper", "error")
  end

  message.setHandler("triggerShipment", startLaunch)
end

function update(dt)
  self.surfaceCheckTimer = self.surfaceCheckTimer - dt
  if self.surfaceCheckTimer <= 0 then
    local onSurface = surfaceCheck()

    if onSurface ~= self.onSurface then
      self.onSurface = onSurface
      if self.onSurface then
        animator.setAnimationState("shipper", "toready")
      else
        animator.setAnimationState("shipper", "toerror")
      end
    end

    self.surfaceCheckTimer = self.surfaceCheckInterval
  end

  if self.launchTimer then
    self.launchTimer = self.launchTimer + dt
    if not self.hasLaunched and self.launchTimer >= self.launchTiming then
      spawnProjectile()
      self.hasLaunched = true
    end
    if self.launchTimer >= self.launchDuration then
      self.launchTimer = nil
      animator.setAnimationState("shipper", "open")
    end
  end

  object.setInteractive(self.onSurface and not self.launchTimer)
end

function surfaceCheck()
  if world.underground(object.position()) then
    return false
  end

  return not world.rectTileCollision(self.surfaceCheckArea, {"Null", "Block", "Dynamic", "Slippery"})
end

function startLaunch()
  self.hasLaunched = false
  self.launchTimer = 0
  animator.setAnimationState("shipper", "ship")

  object.setInteractive(false)
  world.containerTakeAll(entity.id())
end

function spawnProjectile()
  world.spawnProjectile(
    "cropshipment",
    self.launchPosition,
    nil,
    {0, 1},
    false,
    {}
  )
end

function valueOfContents()
  local value = 0
  local allItems = world.containerItems(entity.id())
  for _, item in pairs(allItems) do
    value = value + (self.itemValues[item.name] or 0) * item.count
  end
  return value
end
