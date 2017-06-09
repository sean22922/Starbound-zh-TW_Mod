returnHomeState = {}

function returnHomeState.enterWith(args)
  if args.notification and args.notification.name == "returnHome" then
    return { targetPosition = storage.home.position }
  end

  return nil
end

function returnHomeState.moveTo(position, dt, stateData)
  if stateData.position == nil then
    stateData.position = findGroundPosition(position, -5, 5, true)
    stateData.pather = nil
  end
  if stateData.pather == nil then
    stateData.pather = PathMover:new()
  end
  if not stateData.position then return false end
  return stateData.pather:move(stateData.position, dt)
end

function returnHomeState.update(dt, stateData)
  if not stateData.teleporting then
    local minDistance = config.getParameter("returnHome.minDistance") or 3
    local distance = world.magnitude(mcontroller.position(), stateData.targetPosition)
    if distance < minDistance then
      return true
    end

    stateData.returnHomePath = stateData.returnHomePath or {}
    local moved = returnHomeState.moveTo(stateData.targetPosition, dt, stateData.returnHomePath)
    if moved ~= false then
      if moved == "running" then
        mcontroller.controlFace(self.pathing.deltaX)
        setMovementState(false)
      else
        animator.setAnimationState("movement", "idle")
      end
      return false
    end

    stateData.teleporting = true
    stateData.teleportTime = 0
    storage.teleportTarget = stateData.targetPosition
    status.addEphemeralEffect("beamoutandteleport")
    return false
  else
    stateData.teleportTime = stateData.teleportTime + dt
    return stateData.teleportTime >= 2
  end
end

function performTeleport()
  mcontroller.setPosition(storage.teleportTarget)
end
