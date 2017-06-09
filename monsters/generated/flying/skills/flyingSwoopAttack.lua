-- Swoop through the target, ending on the opposite side

flyingSwoopAttack = {}

function flyingSwoopAttack.enter()
  local toTarget = entity.distanceToEntity(self.target)

  local xDist = math.abs(toTarget[1])
  local swoopDiameter = config.getParameter("swoopDiameter")
  if xDist > swoopDiameter * 1.5 or xDist < swoopDiameter * 0.5 then
    return nil
  end

  return {
    timer = config.getParameter("swoopTime"),
    basePosition = mcontroller.position(),
    height = toTarget[2],
    direction = toTarget[1]
  }
end

function flyingSwoopAttack.update(dt, stateData)
  if util.blockSensorTest("blockedSensors", mcontroller.facingDirection()) then
    return true
  elseif util.blockSensorTest("downSensors", mcontroller.facingDirection()) then
    return true
  elseif not entity.entityInSight(self.target) then
    return true
  elseif mcontroller.isColliding() or mcontroller.liquidPercentage() > 0 then
    return true
  else
    monster.setAggressive(true)
    stateData.timer = stateData.timer - dt
    if stateData.timer < 0 then return true end

    local ratio = stateData.timer / config.getParameter("swoopTime")
    local xOffset = stateData.direction * (1.0 - ratio) * config.getParameter("swoopDiameter")

    local phase = math.pi / 2.0 + math.pi * ratio
    local yOffset = math.cos(phase) * stateData.height

    if stateData.timer < 0.5 then
      animator.setAnimationState("movement", "flying")
    else
      animator.setAnimationState("movement", "gliding")
    end

    local destination = {
      stateData.basePosition[1] + xOffset,
      stateData.basePosition[2] - yOffset
    }

    monster.flyTo(destination)

    return false
  end
end
