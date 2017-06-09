require "/scripts/vec2.lua"

function init()
  self.pregenerateTime = config.getParameter("pregenerateTime")
  self.terraformSize = config.getParameter("terraformSize")
  self.terraformInterferenceBuffer = config.getParameter("terraformInterferenceBuffer", 50)

  self.biome = config.getParameter("terraformBiome")

  local terraformOffset = config.getParameter("terraformOffset", {0, 0})
  self.terraformPosition = vec2.add(entity.position(), terraformOffset)

  storage.uuid = storage.uuid or sb.makeUuid()

  if storage.addTimer then
    register()
  end

  updateInteractive()
  updateAnimation()
end

function onInteraction(args)
  if not (storage.depleted or storage.addTimer) then
    local success, reason = canActivate(self.terraformSize)
    if success then
      triggerAdd()
    else
      return { "ShowPopup", { title = "Activation Failed!", message = string.format("^red;Microformer failed to activate: %s.", reason), sound = "/sfx/interface/nav_insufficient_fuel.ogg"} }
    end
  end
end

function update(dt)
  if storage.addTimer then
    storage.addTimer = storage.addTimer + dt

    if not self.pregenerationFinished then
      self.pregenerationFinished = world.pregenerateAddBiome(self.terraformPosition, self.terraformSize)
      if self.pregenerationFinished then sb.logInfo("pregeneration to add biome finished after %s seconds", storage.addTimer) end
    end

    if storage.addTimer >= self.pregenerateTime[1] and self.pregenerationFinished or (storage.addTimer >= self.pregenerateTime[2]) then
      world.addBiomeRegion(self.terraformPosition, self.biome, "largeClumps", self.terraformSize)

      storage.addTimer = nil
      storage.depleted = true
      object.setConfigParameter("smashOnBreak", true)

      deregister()
      animator.setAnimationState("baseState", "deactivate")
    end
  end

  updateInteractive()
end

function die()
  deregister()
end

function updateInteractive()
  object.setInteractive(not (storage.depleted or storage.addTimer))
end

function updateAnimation()
  if storage.depleted then
    animator.setAnimationState("baseState", "depleted")
  else
    if storage.addTimer then
      animator.setAnimationState("baseState", "active")
    else
      animator.setAnimationState("baseState", "inactive")
    end
  end
end

function triggerAdd()
  storage.addTimer = 0
  self.pregenerationFinished = false
  register()
  animator.setAnimationState("baseState", "activate")
end

function canActivate(newRegionSize)
  if not world.terrestrial() then
    return false, "must be placed on a planet"
  end

  local checkRadius = (newRegionSize / 2) + self.terraformInterferenceBuffer
  local activeTerraformers = world.getProperty("activeTerraformers") or {}
  for k, pos in pairs(activeTerraformers) do
    if k ~= storage.uuid and world.magnitude(self.terraformPosition, pos) < checkRadius then
      return false, "too close to another active terraformer"
      -- return false, string.format("%s too close to another active terraformer %s at %d, %d", storage.uuid, k, pos[1], pos[2])
    end
  end

  return true, ""
end

function register()
  local activeTerraformers = world.getProperty("activeTerraformers") or {}

  activeTerraformers[storage.uuid] = self.terraformPosition

  world.setProperty("activeTerraformers", activeTerraformers)
end

function deregister()
  local activeTerraformers = world.getProperty("activeTerraformers") or {}

  activeTerraformers[storage.uuid] = nil

  world.setProperty("activeTerraformers", activeTerraformers)
end
