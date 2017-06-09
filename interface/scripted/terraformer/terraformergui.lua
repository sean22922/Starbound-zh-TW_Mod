require "/scripts/util.lua"

function init()
  self.pollInterval = config.getParameter("pollInterval", 0.5)
  self.pollTimer = 0

  self.errorTime = config.getParameter("errorTime", 3.0)
  self.errorFlashTime = config.getParameter("errorFlashTime", 0.75)
  self.errorTimer = 0
  self.errorMessage = ""
  self.errorSound = config.getParameter("errorSound")

  self.essenceCostPerTile = config.getParameter("essenceCostPerTile", 1.0)
  self.minTargetSize = config.getParameter("minTargetSize")
  self.targetSizeIncrement = config.getParameter("targetSizeIncrement")
  self.maxStepSize = config.getParameter("maxStepSize")

  self.currentSize = 0
  self.worldSize = world.size()[1]

  widget.setSliderRange("sldTargetSize", 0, self.worldSize)

  self.targetSize = 0

  self.statusMessages = config.getParameter("statusMessages")
  self.errorMessages = config.getParameter("errorMessages")

  widget.setImage("imgPlanetTypeIcon", string.format("/interface/bookmarks/icons/%s.png", config.getParameter("planetType")))

  updateGui()
end

function update(dt)
  self.pollTimer = self.pollTimer - dt
  if self.pollTimer <= 0 and not self.statusPromise then
    self.pollTimer = self.pollInterval
    self.statusPromise = world.sendEntityMessage(pane.sourceEntity(), "getStatus")
  end

  if self.statusPromise and self.statusPromise:finished() then
    local res = self.statusPromise:result()

    self.active = res.active
    self.currentSize = res.currentSize
    self.targetSize = clampSize(self.targetSize)
    widget.setSliderValue("sldTargetSize", self.targetSize)

    self.statusPromise = nil
  end

  if self.activatePromise and self.activatePromise:finished() then
    local res = self.activatePromise:result()

    if res.success then
      self.active = true
      local essenceCost = res.expandAmount * self.essenceCostPerTile
      if player.consumeCurrency("essence", essenceCost) then
        world.sendEntityMessage(pane.sourceEntity(), "confirmActivation")
      else
        world.sendEntityMessage(pane.sourceEntity(), "cancelActivation")
      end
    else
      self.active = false
      setError(res.errorCode)
      if self.errorSound then
        pane.playSound(self.errorSound)
      end
    end

    self.activatePromise = nil
  end

  self.errorTimer = math.max(0, self.errorTimer - dt)

  updateGui()
end

function dismissed()
  if self.activatePromise then
    world.sendEntityMessage(pane.sourceEntity(), "cancelActivation")
  end
end

function updateGui()
  local playerEssence = player.currency("essence")
  local essenceCost = (self.targetSize - self.currentSize) * self.essenceCostPerTile
  local essenceTextDirective = ""
  if essenceCost > 0 then
    if playerEssence >= essenceCost then
      essenceTextDirective = "^green;"
    else
      essenceTextDirective = "^red;"
    end
  end
  widget.setText("lblEssenceCount", string.format("%s%s / %s", essenceTextDirective, playerEssence, essenceCost > 0 and essenceCost or "--"))

  local currentRatio = self.currentSize / self.worldSize
  local targetRatio = self.targetSize / self.worldSize
  widget.setProgress("prgCurrentProgress", currentRatio)
  widget.setProgress("prgPreviewProgress", targetRatio)
  widget.setProgress("prgAvailable", math.min(self.currentSize + self.maxStepSize, self.worldSize) / self.worldSize)

  local ready = false
  local allowSlide = true
  local statusMessage = ""

  if self.currentSize >= self.worldSize then
    statusMessage = self.statusMessages.worldComplete
    allowSlide = false
  elseif self.active == nil then
    statusMessage = self.statusMessages.connecting
    allowSlide = false
  elseif self.active then
    statusMessage = self.statusMessages.active
    allowSlide = false
  elseif self.activatePromise then
    allowSlide = false
  elseif playerEssence < essenceCost then
    statusMessage = self.statusMessages.insufficientEssence
  elseif essenceCost > 0 then
    ready = true

    if self.targetSize == self.currentSize + self.maxStepSize then
      statusMessage = string.format(self.statusMessages.maxStepSize, self.maxStepSize)
    end
  end

  if self.errorTimer > 0 then
    local textDirective = ((self.errorTimer % 0.25 > 0.125) and (self.errorTime - self.errorTimer <= self.errorFlashTime)) and "^orange;" or "^red;"
    statusMessage = textDirective .. self.errorMessage
  end

  widget.setButtonEnabled("btnTerraform", ready)
  widget.setSliderEnabled("sldTargetSize", allowSlide)
  widget.setButtonEnabled("btnIncreaseTargetSize", allowSlide)
  widget.setButtonEnabled("btnDecreaseTargetSize", allowSlide)
  widget.setText("lblCurrentStatus", statusMessage)
end

function doTerraform()
  if not self.activatePromise then
    clearError()
    self.activatePromise = world.sendEntityMessage(pane.sourceEntity(), "activate", self.targetSize)
  end
end

function clampSize(newSize)
  return math.min(math.min(math.max(math.max(newSize, self.minTargetSize), self.currentSize), self.currentSize + self.maxStepSize), self.worldSize)
end

function updateTargetSize()
  self.targetSize = clampSize(widget.getSliderValue("sldTargetSize"))
  widget.setSliderValue("sldTargetSize", self.targetSize)
end

function increaseTargetSize()
  self.targetSize = clampSize(self.targetSize + self.targetSizeIncrement)
  widget.setSliderValue("sldTargetSize", self.targetSize)
end

function decreaseTargetSize()
  self.targetSize = clampSize(self.targetSize - self.targetSizeIncrement)
  widget.setSliderValue("sldTargetSize", self.targetSize)
end

function setError(errorCode)
  self.errorTimer = self.errorTime
  self.errorMessage = self.errorMessages[errorCode]
end

function clearError()
  self.errorTimer = 0
end
