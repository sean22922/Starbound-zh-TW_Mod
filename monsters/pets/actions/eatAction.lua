eatAction = {
}

function eatAction.enterWith(args)
  if not args.eatTarget then return nil end

  if status.resource("hunger") < config.getParameter("actionParams.eat.minHunger", 40) then
    return nil
  end

  --Make sure the target is valid
  local entityType = world.entityType(args.eatTarget)
  if not world.entityExists(args.eatTarget) or entityType ~= "itemDrop" then
    return nil
  end

  return {
    targetId = args.eatTarget,
    approachDistance = config.getParameter("actionParams.eat.distance", 2),
    runDistance = 5,
    eatTimer = 2,
    approachTimer = 5,
    eating = false
  }
end

function eatAction.update(dt, stateData)
  if not world.entityExists(stateData.targetId) then return true end

  local targetPosition = world.entityPosition(stateData.targetId)
  local targetDistance = world.magnitude(targetPosition, mcontroller.position())

  local running = targetDistance > stateData.runDistance

  --Approach the target
  if not approachPoint(dt, targetPosition, stateData.approachDistance, running) then
    stateData.approachTimer = stateData.approachTimer - dt

    if stateData.approachTimer < 0 or self.pathing.stuck then
      return true, 5
    end

    return false
  end

  if stateData.eating == false then
    animator.setAnimationState("movement", "eat")
    stateData.eating = true
  end

  stateData.eatTimer = stateData.eatTimer - dt

  if stateData.eatTimer < 0 then
    local targetType = world.entityType(stateData.targetId)
    if (targetType == "itemDrop" and eatAction.consumeItemDrop(stateData)) then
      return true, config.getParameter("actionParams.eat.cooldown")
    end
  end

  return false
end

function eatAction.consumeItemDrop(stateData)
  local oldDropPosition = world.entityPosition(stateData.targetId)
  local itemDrop = world.takeItemDrop(stateData.targetId)
  if itemDrop then
    local foodLiking = itemFoodLiking(itemDrop.name)

    if foodLiking > 50 then
      emote("happy")
    else
      emote("sad")
    end

    local numEaten = math.min(itemDrop.count, math.ceil(status.resource("hunger") / 40))
    status.modifyResource("hunger", -40 * numEaten)

    if numEaten < itemDrop.count then
      world.spawnItem(itemDrop.name, oldDropPosition, itemDrop.count - numEaten, itemDrop.parameters)
    end

    return true
  end
end
