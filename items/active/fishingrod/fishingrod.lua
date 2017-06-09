require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/rope.lua"
require "/scripts/activeitem/stances.lua"

function init()
  self.lureProjectile = config.getParameter("lureProjectile")
  self.castVector = config.getParameter("castVector", {1, 1})

  self.reelParameters = config.getParameter("reelParameters")

  self.rope = {}
  self.availableRopeLength = self.reelParameters.reelOutLength
  self.fullyExtended = false

  self.ropeColor = config.getParameter("ropeColor")
  self.ropeFlashColor = config.getParameter("ropeFlashColor")
  self.ropeFlashTime = config.getParameter("ropeFlashTime", 0.08)

  self.corrodeLiquidIds = config.getParameter("corrodeLiquidIds", {})
  self.corrodeParticle = config.getParameter("corrodeParticle")

  self.burnLiquidIds = config.getParameter("burnLiquidIds", {})
  self.burnParticle = config.getParameter("burnParticle")

  self.windupTime = 0
  self.minWindupTime = config.getParameter("minWindupTime", 0.25)
  self.maxWindupTime = config.getParameter("maxWindupTime", 1.5)
  self.windupAngleRange = config.getParameter("windupAngleRange", {-40, 80})
  self.maxCastSpeed = config.getParameter("maxCastSpeed", 50)

  self.catchDistance = config.getParameter("catchDistance", 1.75)

  message.setHandler("fishOn", function(_, _, fishId)
      if self.lureId then
        self.hookedId = fishId
        activeItem.setCameraFocusEntity(self.hookedId)
        if world.entityExists(self.lureId) then
          world.callScriptedEntity(self.lureId, "kill")
        end
        self.lureId = nil
        animator.playSound("bite")
      end
    end)

  message.setHandler("lineBreak", function()
      animator.playSound("linebreak")
      cancel()
    end)

  initStances()
  setStance("idle")
end

function update(dt, fireMode, shiftHeld, controls)
  checkConnected()

  local edgeTrigger = fireMode ~= self.lastFireMode
  self.lastFireMode = fireMode

  if connected() and fireMode == "alt" and edgeTrigger then
    cancel()
  elseif not connected() and self.windupTime == 0 and fireMode == "primary" and edgeTrigger then
    setStance("windup")
    self.windupTime = dt
    self.stance.armRotation = util.interpolateHalfSigmoid(self.windupTime / self.maxWindupTime, self.windupAngleRange)
  elseif self.windupTime > 0 and fireMode == "primary" then
    self.windupTime = math.min(self.windupTime + dt, self.maxWindupTime)
    self.stance.armRotation = util.interpolateHalfSigmoid(self.windupTime / self.maxWindupTime, self.windupAngleRange)
  elseif self.windupTime > 0 and fireMode ~= "primary" then
    if self.windupTime > self.minWindupTime then
      local castSpeed = util.lerp(self.windupTime / self.maxWindupTime, 0, 1) * self.maxCastSpeed
      startCast(castSpeed)
    else
      cancel()
    end
  elseif connected() and (fireMode == "primary" or controls.up) then
    if self.lureId and world.magnitude(castPosition(), world.entityPosition(self.lureId)) < self.catchDistance then
      cancel()
    elseif self.hookedId and world.magnitude(castPosition(), world.entityMouthPosition(self.hookedId)) < self.catchDistance then
      world.sendEntityMessage(self.hookedId, "catch")
      catch()
    else
      controls["reel"] = true
      setStance("reel")
    end
  elseif connected() then
    setStance("cast")
  end

  updateAim()
  updateStance(dt)
  updateRod()
  updateRope()
  updateConnected(controls)

  checkLiquids()

  -- world.debugPoint(castPosition(), "blue")

  if connected() then
    -- local dist = world.magnitude(castPosition(), (self.lureId and world.entityPosition(self.lureId)) or (self.hookedId and world.entityPosition(self.hookedId)))
    -- world.debugText(string.format("distance: %.2f", dist), vec2.add(mcontroller.position(), {2, 3}), (self.lastDebugDist and self.lastDebugDist < dist) and "red" or "blue")
    -- self.lastDebugDist = dist

    mcontroller.controlModifiers({movementSuppressed = true, facingSuppressed = true})

    local fishFighting = false
    if self.hookedId then
      local fightPromise = world.sendEntityMessage(self.hookedId, "fighting")
      if fightPromise:finished() and fightPromise:result() then
        fishFighting = true
      end
    end

    if controls.reel then
      if fishFighting then
        animator.setAnimationState("reel", "stretch")
      else
        animator.setAnimationState("reel", "in")
      end
    elseif (not self.fullyExtended and controls.down) or (self.hookedId and world.liquidAt(world.entityPosition(self.hookedId))) then
      animator.setAnimationState("reel", "out")
    else
      animator.setAnimationState("reel", "idle")
    end

    if controls.reel and fishFighting and os.clock() % (2 * self.ropeFlashTime) < self.ropeFlashTime then
      activeItem.setScriptedAnimationParameter("ropeColor", self.ropeFlashColor)
    else
      activeItem.setScriptedAnimationParameter("ropeColor", self.ropeColor)
    end
  else
    animator.setAnimationState("reel", "idle")
  end
end

function uninit()
  cancel()
end

function startCast(castSpeed)
  self.windupTime = 0
  setStance("cast")

  if world.lineTileCollision(mcontroller.position(), castPosition()) then
    cancel()
    return
  end

  animator.playSound("cast")

  self.lureId = world.spawnProjectile(
    self.lureProjectile,
    castPosition(),
    activeItem.ownerEntityId(),
    {self.castVector[1] * self.aimDirection, self.castVector[2]},
    false,
    {
      speed = castSpeed,
      reelParameters = self.reelParameters
    }
  )

  if self.lureId then
    activeItem.setCameraFocusEntity(self.lureId)
    status.setPersistentEffects("fishing", {{stat = "activeMovementAbilities", amount = 1}})
  end
end

function cancel()
  self.windupTime = 0
  setStance("idle")
  if self.lureId then
    if world.entityExists(self.lureId) then
      world.callScriptedEntity(self.lureId, "kill")
    end
    self.lureId = nil
  end
  if self.hookedId then
    if world.entityExists(self.hookedId) then
      world.sendEntityMessage(self.hookedId, "unhook")
    end
    self.hookedId = nil
  end
  activeItem.setCameraFocusEntity()
  status.setPersistentEffects("fishing", {})

  for i = 1, #self.rope do
    activeItem.setScriptedAnimationParameter("p" .. i, nil)
  end
  self.rope = {}
end

function catch()
  world.sendEntityMessage(activeItem.ownerEntityId(), "addCollectable", "fishing", world.monsterType(self.hookedId))

  self.hookedId = nil
  self.lureId = nil

  activeItem.setCameraFocusEntity()
  status.setPersistentEffects("fishing", {})

  for i = 1, #self.rope do
    activeItem.setScriptedAnimationParameter("p" .. i, nil)
  end
  self.rope = {}

  setStance("catch")
  animator.playSound("catch")
end

function castPosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint("fishingrod", "endpoint")))
end

function connected()
  return self.lureId or self.hookedId
end

function checkConnected()
  if self.lureId and not world.entityExists(self.lureId) and not self.hookedId then
    self.lureId = nil
    cancel()
  end

  if self.hookedId and not world.entityExists(self.hookedId) then
    self.hookedId = nil
    cancel()
  end
end

function updateConnected(controls)
  if self.lureId then
    world.sendEntityMessage(self.lureId, "updateLure", self.rope[#self.rope - 1], self.availableRopeLength, controls)
  end

  if self.hookedId then
    world.sendEntityMessage(self.hookedId, "updateHooked", self.rope[#self.rope - 1], controls)
  end
end

function updateRod()
  if self.lureId then
    animator.setAnimationState("load", "medium")
  elseif self.hookedId then
    animator.setAnimationState("load", "heavy")
  else
    animator.setAnimationState("load", "light")
  end

  activeItem.setScriptedAnimationParameter("ropeOffset", animator.partPoint("fishingrod", "endpoint"))
end

function updateRope()
  local newRope = {}
  if connected() then
    local endPoint = self.lureId and world.callScriptedEntity(self.lureId, "linePosition") or world.entityMouthPosition(self.hookedId)
    if #self.rope == 0 then
      newRope = {castPosition(), endPoint}
    else
      newRope = copy(self.rope)
      table.insert(newRope, 1, world.nearestTo(newRope[1], castPosition()))
      table.insert(newRope, world.nearestTo(newRope[#newRope], endPoint))
    end
  end

  windRope(newRope)

  local previousRopeCount = #self.rope
  self.rope = newRope

  for i = 2, #self.rope do
    activeItem.setScriptedAnimationParameter("p" .. i, self.rope[i])
  end
  for i = #self.rope + 1, previousRopeCount do
    activeItem.setScriptedAnimationParameter("p" .. i, nil)
  end

  self.availableRopeLength = self.reelParameters.reelOutLength
  if #self.rope > 2 then
    for i = 2, # self.rope - 1 do
      self.availableRopeLength = self.availableRopeLength - world.magnitude(self.rope[i], self.rope[i - 1])
    end
  end

  if connected() then
    local lastSegmentLength = world.magnitude(self.rope[#self.rope], self.rope[#self.rope - 1])
    if self.availableRopeLength - lastSegmentLength < -self.reelParameters.lineBreakMargin then
      animator.playSound("linebreak")
      cancel()
    elseif self.availableRopeLength <= lastSegmentLength then
      self.fullyExtended = true
    else
      self.fullyExtended = false
    end
  end

  if not self.destroyTicks then
    activeItem.setScriptedAnimationParameter("ropeParticleDensity", false)
  end
end

function checkLiquids()
  if connected() then
    if self.destroyTicks then
      self.destroyTicks = self.destroyTicks - 1
      if self.destroyTicks <= 0 then
        self.destroyTicks = nil
        cancel()
      end
    else
      local endPoint = self.lureId and world.entityPosition(self.lureId) or world.entityMouthPosition(self.hookedId)
      local liquid = world.liquidAt(endPoint)
      if liquid then
        local corrode, burn = false, false
        for i, liquidId in ipairs(self.corrodeLiquidIds) do
          if liquidId == liquid[1] then
            corrode = true
          end
        end
        for i, liquidId in ipairs(self.burnLiquidIds) do
          if liquidId == liquid[1] then
            burn = true
          end
        end

        if corrode or burn then
          self.destroyTicks = config.getParameter("destroyTicks", 5)
          activeItem.setScriptedAnimationParameter("ropeParticleDensity", config.getParameter("destroyRopeParticleDensity", 0.1))
          if corrode then
            activeItem.setScriptedAnimationParameter("ropeParticle", self.corrodeParticle)
            animator.playSound("corrode")
          else
            activeItem.setScriptedAnimationParameter("ropeParticle", self.burnParticle)
            animator.playSound("burn")
          end
        end
      end
    end
  end
end
