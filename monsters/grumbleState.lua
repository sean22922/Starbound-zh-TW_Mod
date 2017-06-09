require "/scripts/util.lua"

grumbleState = {}

function grumbleState.enterWith(args)
  if args.notification and args.notification.name == "grumble" then
    return { emoteCooldown = 0 }
  end
  return nil
end

function grumbleState.enter()
  if storage.grumbles and #storage.grumbles > 0 then
    return { emoteCooldown = 0 }
  end
  return nil
end

function grumbleState.update(dt, stateData)
  if not storage.grumbles or #storage.grumbles == 0 then
    return true
  end

  stateData.emoteCooldown = stateData.emoteCooldown - dt
  if stateData.emoteCooldown <= 0 then
    if emote then
      emote("sad")
    end
    stateData.emoteCooldown = util.randomInRange(config.getParameter("tenant.emoteCooldownTimeRange"))
  end

  return false
end
