require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/stateMachine.lua"
require "/scripts/companions/capturable.lua"

function init()
  local scripts = config.getParameter("scripts")
  local states = stateMachine.scanScripts(scripts, "(%a+State)%.lua")
  self.state = stateMachine.create(states)
  storage.stateStage = storage.stateStage or "appear"

  self.swimSpeed = config.getParameter("swimSpeed", 3)
  self.hookedSpeed = config.getParameter("hookedSpeed", 15)
  self.biteSpeed = config.getParameter("biteSpeed", 30)

  self.swimForce = config.getParameter("swimForce")

  self.blockedSensors = config.getParameter("blockedSensors")
  self.surfaceSensors = config.getParameter("surfaceSensors")
  self.groundSensors = config.getParameter("groundSensors")

  self.rotation = 0
  animator.setAnimationState("movement", "swimSlow")

  self.currentOpacity = 0
  self.targetOpacity = 1
  self.currentColorFade = 0
  self.targetColorFade = 0
  self.fadeTime = config.getParameter("fadeTime", 1.0)
  self.colorFadeDistance = config.getParameter("colorFadeDistance", {3, 8})

  self.lureId = config.getParameter("lureId")
  self.ownerId = config.getParameter("ownerId")
  self.reelParameters = config.getParameter("reelParameters")

  self.rodPosition = config.getParameter("rodPosition")
  self.controls = {}

  capturable.init()

  message.setHandler("updateHooked", function(_, _, rodPosition, controls)
      self.rodPosition = rodPosition
      self.controls = controls
    end)

  message.setHandler("unhook", function()
      self.lureId = nil
      self.ownerId = nil
      if storage.stateStage ~= "landed" then
        despawn()
      end
    end)

  message.setHandler("catch", function()
      local toOwner = world.distance(world.entityPosition(self.ownerId), mcontroller.position())
      mcontroller.setVelocity({util.toDirection(toOwner[1]) * 15, 25})
      storage.stateStage = "landed"
      self.lureId = nil
      self.ownerId = nil
      self.state.pickState()
    end)

  message.setHandler("fighting", function()
      return self.fighting
    end)

  self.inLiquid = true
  self.toLure = {mcontroller.facingDirection() * 100, 20}

  -- sb.logInfo("Fishing monster %s spawned", entity.id())
end

function die()
  if not capturable.justCaptured then
    capturable.die()
  end
end

function shouldDie()
  return status.resource("health") <= 0 or capturable.justCaptured
end

function update(dt)
  capturable.update(dt)

  updateLure()
  updateOwner()
  if not self.lureId and not self.ownerId and storage.stateStage ~= "landed" then
    despawn()
  end

  self.state.update(dt)

  self.inLiquid = mcontroller.liquidPercentage() > 0.9

  updateFade(dt)
end

function updateLure()
  if self.lureId then
    if world.entityExists(self.lureId) then
      local pos = mcontroller.position()
      self.lurePosition = world.entityPosition(self.lureId)
      if not world.liquidAt(self.lurePosition) or world.lineTileCollision(pos, self.lurePosition) then
        self.lureId = nil
        despawn()
      else
        self.toLure = world.distance(self.lurePosition, pos)
      end
    else
      self.lureId = nil
    end
  else
    self.toLure = {mcontroller.facingDirection() * 100, 20}
  end
end

function updateOwner()
  if self.ownerId and not world.entityExists(self.ownerId) then
    self.ownerId = nil
  end
end

function updateFade(dt)
  if storage.stateStage == "landed" or storage.stateStage == "hooked" or not self.inLiquid then
    self.targetOpacity = 1
    self.targetColorFade = 1
  else
    local lureDist = vec2.mag(self.toLure)
    self.targetColorFade = 1 - math.min(1, math.max(0, (lureDist - self.colorFadeDistance[1]) / (self.colorFadeDistance[2] - self.colorFadeDistance[1])))
  end

  if self.targetOpacity < self.currentOpacity then
    self.currentOpacity = math.max(self.targetOpacity, self.currentOpacity - dt / self.fadeTime)
  elseif self.targetOpacity > self.currentOpacity then
    self.currentOpacity = math.min(self.targetOpacity, self.currentOpacity + dt / self.fadeTime)
  end

  if self.targetColorFade < self.currentColorFade then
    self.currentColorFade = math.max(self.targetColorFade, self.currentColorFade - dt / self.fadeTime)
  elseif self.targetColorFade > self.currentColorFade then
    self.currentColorFade = math.min(self.targetColorFade, self.currentColorFade + dt / self.fadeTime)
  end

  animator.setGlobalTag("directives", string.format("?fade=000000FF;%.2f?multiply=FFFFFF%02X", 1 - self.currentColorFade, math.floor(self.currentOpacity * 255)))
end

function move(direction, speed)
  if not self.inLiquid then return end

  local moveDirection = vec2.norm(direction)

  -- calculate rotation
  setBodyDirection(moveDirection)

  -- move
  mcontroller.controlApproachVelocity(vec2.mul(moveDirection, speed), self.swimForce)
end

function blocked(sensors)
  for i, sensor in ipairs(sensors) do
    -- world.debugPoint(monster.toAbsolutePosition(sensor), "green")
    if not world.liquidAt(monster.toAbsolutePosition(sensor)) then
      return true
    end
  end

  return false
end

function setBodyDirection(direction)
  if direction[2] ~= 0 then
    local rotateAmount = vec2.angle(direction)
    if direction[1] < 0 then rotateAmount = math.pi - rotateAmount end
    self.rotation = rotateAmount
  else
    self.rotation = 0
  end
  animator.rotateGroup("all", self.rotation)
  mcontroller.controlFace(direction[1])
  mcontroller.setRotation(self.rotation * mcontroller.facingDirection())
end

function despawn()
  if storage.stateStage ~= "despawn" then
    storage.stateStage = "despawn"
    self.state.pickState()
  end
end
