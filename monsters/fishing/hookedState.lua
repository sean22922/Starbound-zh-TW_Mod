require "/scripts/util.lua"
require "/scripts/vec2.lua"

hookedState = {}

function hookedState.enter()
  if storage.stateStage == "hooked" then
    return {
      fightChance = config.getParameter("fightChance", 0.5),
      tensionTimer = 0,
      struggleTimer = 0
    }
  end
end

function hookedState.enteringState(stateData)
  animator.setAnimationState("movement", "panicFast")
  script.setUpdateDelta(1)
end

function hookedState.update(dt, stateData)
  local toRod = world.distance(self.rodPosition, mcontroller.position())

  if self.inLiquid then
    stateData.struggleTimer = math.max(0, stateData.struggleTimer - dt)
    if stateData.struggleTimer == 0 then
      if self.fighting == false and math.random() < stateData.fightChance then
        self.fighting = true
        stateData.tensionTimer = 0
        stateData.fightChance = config.getParameter("fightChance", 0.5)
        stateData.struggleTimer = util.randomInRange(config.getParameter("fightTimeRange", {1.2, 1.5}))
        stateData.struggleAngle = math.pi
      else
        if not self.fighting then
          stateData.fightChance = stateData.fightChance + 0.1
        end
        self.fighting = false
        stateData.struggleTimer = util.randomInRange(config.getParameter("struggleTimeRange", {0.7, 1.5}))
        stateData.struggleAngle = util.randomDirection() * math.pi * 0.5
      end
    end

    local rodAngle = vec2.angle(toRod)
    if self.fighting then
      if self.controls.reel then
        stateData.tensionTimer = stateData.tensionTimer + dt
        if stateData.tensionTimer > self.reelParameters.lineBreakTime then
          world.sendEntityMessage(self.ownerId, "lineBreak")
          return false
        end
      else
        stateData.tensionTimer = math.max(0, stateData.tensionTimer - dt)
      end

      local moveDirection = vec2.withAngle(rodAngle + stateData.struggleAngle, self.controls.down and self.fastSpeed or 2)
      mcontroller.controlFace(moveDirection[1])
      setBodyDirection(moveDirection)
      mcontroller.controlApproachVelocity(moveDirection, self.swimForce)
    else
      local samplePoint = vec2.add(mcontroller.position(), vec2.withAngle(rodAngle + stateData.struggleAngle + util.toDirection(stateData.struggleAngle) * -0.25, 4))
      -- world.debugPoint(samplePoint, "blue")
      if not world.liquidAt(samplePoint) then
        stateData.struggleAngle = -stateData.struggleAngle
        stateData.struggleTimer = math.max(stateData.struggleTimer, 0.5)
      end

      local reelAngleAdjust
      if self.controls.reel then
        reelAngleAdjust = util.toDirection(stateData.struggleAngle) * -config.getParameter("reelInAngle", 0.3)
      else
        reelAngleAdjust = util.toDirection(stateData.struggleAngle) * 0.2
      end

      local moveAngle = rodAngle + stateData.struggleAngle + reelAngleAdjust

      move(vec2.withAngle(moveAngle), self.hookedSpeed)
    end
  else
    self.fighting = false
    if self.controls.reel then
      mcontroller.controlApproachVelocityAlongAngle(vec2.angle(toRod), self.reelParameters.reelSpeed, 1000)
    elseif not self.controls.down then
      mcontroller.controlApproachVelocityAlongAngle(vec2.angle(toRod), 0, 1000)
    end
  end

  if not self.inLiquid then
    self.rotation = vec2.angle(toRod)
    if mcontroller.facingDirection() < 0 then
      self.rotation = math.pi - self.rotation
    end
    animator.rotateGroup("all", self.rotation)
    mcontroller.setRotation(self.rotation * mcontroller.facingDirection())
  else
    setBodyDirection(mcontroller.velocity())
  end

  return false
end

function hookedState.leavingState(stateData)
  script.setUpdateDelta(5)
  self.fighting = nil
end
