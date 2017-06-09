scatterState = {}

function scatterState.enterWith(event)
  if event.scatterSource then
    return {
      source = event.scatterSource,
      timer = config.getParameter("scatterTime")
    }
  end

  return nil
end

function scatterState.update(dt, stateData)
  if stateData.timer < 0 then
    return true
  end
  stateData.timer = stateData.timer - dt

  local movement = world.distance(mcontroller.position(), stateData.source)
  local distance = world.magnitude(movement)
  if distance > config.getParameter("scatterDistance") then
    return true
  end

  self.movement = movement
  self.movementWeight = config.getParameter("scatterMovementWeight")
  return false
end
