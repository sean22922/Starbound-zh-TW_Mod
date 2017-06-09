require "/scripts/util.lua"

investigateState = {}

function investigateState.enter()
  local targetIds = world.entityQuery(mcontroller.position(), config.getParameter("investigateTriggerDistance"), { includedTypes = {"itemDrop"}, order = "nearest" })
  for k,targetId in pairs(targetIds) do
    if entity.entityInSight(targetId) then
      return {
        target = targetId,
        maxDistance = util.randomInRange(config.getParameter("investigateLoseInterestRange")),
        timer = util.randomInRange(config.getParameter("investigateTimeRange"))
      }
    end
  end

  return nil
end

function investigateState.update(dt, stateData)
  if not world.entityExists(stateData.target) then
    return true
  end

  if not entity.entityInSight(stateData.target) then
    return true
  end

  stateData.timer = stateData.timer - dt
  if stateData.timer < 0 then
    return true, config.getParameter("investigateCooldownTime")
  end

  local toTarget = entity.distanceToEntity(stateData.target)
  local distance = world.magnitude(toTarget)
  if distance > stateData.maxDistance then
    return true
  end

  if distance < config.getParameter("investigateStopDistance") then
    return true, config.getParameter("investigateCooldownTime")
  end

  self.movement = toTarget
  return false
end
