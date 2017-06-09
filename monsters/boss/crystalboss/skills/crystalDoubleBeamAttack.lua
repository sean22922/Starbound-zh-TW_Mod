crystalDoubleBeamAttack = {}

--------------------------------------------------------------------------------
function crystalDoubleBeamAttack.enter()
  if not hasTarget() then return nil end

  return {
    windupTimer = 0.6,
    timer = config.getParameter("crystalDoubleBeamAttack.skillTime", 8),
    rotateInterval = config.getParameter("crystalDoubleBeamAttack.rotateInterval", 8),
    angleRange = math.pi * 0.2,
    initialAngle = math.pi / 4,
    angleAdjustment = -math.pi * 0.5, --Because beams point down at 0 angle
    winddownTimer = 0.6,
    bobInterval = 0.5,
    bobHeight = 0.1
  }
end

--------------------------------------------------------------------------------
function crystalDoubleBeamAttack.enteringState(stateData)
  animator.setAnimationState("firstBeams", "windup")
  animator.setAnimationState("secondBeams", "windup")
  animator.setAnimationState("eye", "windup")
  animator.setAnimationState("beamglow", "on")

  crystalDoubleBeamAttack.damagePerSecond = config.getParameter("crystalDoubleBeamAttack.damagePerSecond")

  crystalDoubleBeamAttack.rotateBeams(stateData.angleAdjustment + stateData.initialAngle, true)
end

--------------------------------------------------------------------------------
function crystalDoubleBeamAttack.update(dt, stateData)
  crystalDoubleBeamAttack.bob(dt, stateData)

  if stateData.windupTimer > 0 then
    stateData.windupTimer = stateData.windupTimer - dt
    return false
  end

  if stateData.timer > 0 then
    crystalDoubleBeamAttack.setBeamLightsActive(true)

    local angleFactor = math.max(0, (stateData.rotateInterval - stateData.timer)) / stateData.rotateInterval
    local angle = crystalDoubleBeamAttack.angleFactorFromTime(stateData.timer, stateData.rotateInterval) * stateData.angleRange + stateData.initialAngle

    crystalDoubleBeamAttack.rotateBeams(stateData.angleAdjustment + angle, true)

    local powerMultiplier = root.evalFunction("monsterLevelPowerMultiplier", monster.level())
    crystalDoubleBeamAttack.spawnProjectiles(angle, crystalDoubleBeamAttack.damagePerSecond * powerMultiplier * dt)

    stateData.timer = stateData.timer - dt
    if stateData.timer < 0 then
      animator.setAnimationState("firstBeams", "winddown")
      animator.setAnimationState("secondBeams", "winddown")
      animator.setAnimationState("eye", "winddown")
    end

    return false
  end

  if stateData.winddownTimer > 0 then
    stateData.winddownTimer = stateData.winddownTimer - dt
    return false
  end

  return true
end

function crystalDoubleBeamAttack.angleFactorFromTime(timer, interval)
  local modTimer = interval - (timer % interval)
  return math.sin(modTimer / interval * math.pi * 2)
end

function crystalDoubleBeamAttack.leavingState(stateData)
  animator.setAnimationState("firstBeams", "idle")
  animator.setAnimationState("secondBeams", "idle")
  animator.setAnimationState("beamglow", "off")

  crystalDoubleBeamAttack.setBeamLightsActive(false)
end

function crystalDoubleBeamAttack.rotateBeams(angle, instant)
  animator.rotateGroup("beam1", angle, instant)
  animator.rotateGroup("beam2", angle + math.pi, instant)
  animator.rotateGroup("beam3", -angle, instant)
  animator.rotateGroup("beam4", -angle + math.pi, instant)
end

function crystalDoubleBeamAttack.spawnProjectiles(angle, power)
  --Beam 1 
  local newAngle = angle
  local aimVector = {math.cos(newAngle), math.sin(newAngle)}
  world.spawnProjectile("crystalbeamdamage", mcontroller.position(), entity.id(), aimVector, true, {power = power, damageRepeatGroup = "crystalbossbeam"})
  crystalDoubleBeamAttack.setBeamLightPosition("beam1", newAngle)

  --Beam 2
  newAngle = angle + math.pi
  aimVector = {math.cos(newAngle), math.sin(newAngle)}
  world.spawnProjectile("crystalbeamdamage", mcontroller.position(), entity.id(), aimVector, true, {power = power, damageRepeatGroup = "crystalbossbeam"})
  crystalDoubleBeamAttack.setBeamLightPosition("beam2", newAngle)
  
  --Beam 3
  newAngle = -angle
  aimVector = {math.cos(newAngle), math.sin(newAngle)}
  world.spawnProjectile("crystalbeamdamage", mcontroller.position(), entity.id(), aimVector, true, {power = power, damageRepeatGroup = "crystalbossbeam"})
  crystalDoubleBeamAttack.setBeamLightPosition("beam3", newAngle)
  
  --Beam 4
  newAngle = -angle + math.pi
  aimVector = {math.cos(newAngle), math.sin(newAngle)}
  world.spawnProjectile("crystalbeamdamage", mcontroller.position(), entity.id(), aimVector, true, {power = power, damageRepeatGroup = "crystalbossbeam"})
  crystalDoubleBeamAttack.setBeamLightPosition("beam4", newAngle)
end

function crystalDoubleBeamAttack.setBeamLightsActive(active)
  animator.setLightActive("beam1", active)
  animator.setLightActive("beam1-2", active)
  animator.setLightActive("beam2", active)
  animator.setLightActive("beam2-2", active)
  animator.setLightActive("beam3", active)
  animator.setLightActive("beam3-2", active)
  animator.setLightActive("beam4", active)
  animator.setLightActive("beam4-2", active)
end

function crystalDoubleBeamAttack.setBeamLightPosition(light, angle)
  animator.setLightPosition(light, vec2.rotate({32, 0}, angle))
  animator.setLightPosition(light.."-2", vec2.rotate({20, 0}, angle))
end

function crystalDoubleBeamAttack.bob(dt, stateData)
  local bobFactor = (stateData.bobInterval - (stateData.timer % stateData.bobInterval)) / stateData.bobInterval
  local bobOffset = math.sin(bobFactor * math.pi * 2) * stateData.bobHeight
  local targetPosition = {self.spawnPosition[1], self.spawnPosition[2] + bobOffset}
  local toTarget = world.distance(targetPosition, mcontroller.position())

  mcontroller.controlApproachVelocity(vec2.mul(toTarget, 1/dt), 30)
end
