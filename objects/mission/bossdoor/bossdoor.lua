require "/scripts/rect.lua"
require "/scripts/util.lua"

function init()
  setupMaterialSpaces()

  self.open = false

  object.setInteractive(true)

  object.setMaterialSpaces(self.closedMaterialSpaces)
  animator.setAnimationState("doorState", "closed")
  physics.setForceEnabled("right", false)
  physics.setForceEnabled("left", false)

  self.playerQueryArea = config.getParameter("playerQueryArea")
  if object.direction() < 0 then
    self.playerQueryArea = rect.flipX(self.playerQueryArea)
  end
  self.playerQueryArea = rect.translate(self.playerQueryArea, entity.position())

  self.closeTime = config.getParameter("closeTime", 0.5)
  self.timer = 0

  self.cooldownTime = config.getParameter("cooldownTime", 1.0)
  self.cooldownTimer = 0
end

function onInteraction(args)
  -- Only allow opening from behind the door
  if self.cooldownTimer == 0 and args.source[1] * object.direction() < 0 then
    openDoor()
  end
end

function queryPlayers(area)
  return world.entityQuery(rect.ll(area), rect.ur(area), { includedTypes = { "player" } })
end

function update(dt)
  if self.open then
    self.cooldownTimer = self.cooldownTime
    self.timer = math.max(self.timer - script.updateDt(), 0)

    if self.timer == 0 then
      local players = queryPlayers(self.playerQueryArea)

      if #players == 0 then
        closeDoor()
      end
    end
  else
    self.cooldownTimer = math.max(self.cooldownTimer - dt, 0)
  end
end

function openDoor()
  object.setMaterialSpaces(self.openMaterialSpaces)
  animator.setAnimationState("doorState", "open")
  animator.playSound("open")
  physics.setForceEnabled(object.direction() > 0 and "right" or "left", true)
  self.timer = self.closeTime
  self.open = true
end

function closeDoor()
  object.setMaterialSpaces(self.closedMaterialSpaces)
  animator.setAnimationState("doorState", "closed")
  animator.playSound("close")
  physics.setForceEnabled(object.direction() > 0 and "right" or "left", false)
  self.open = false
end

function setupMaterialSpaces()
  self.closedMaterialSpaces = config.getParameter("closedMaterialSpaces")
  if not self.closedMaterialSpaces then
    self.closedMaterialSpaces = {}
    for i, space in ipairs(object.spaces()) do
      table.insert(self.closedMaterialSpaces, {space, "metamaterial:objectsolid"})
    end
  end
  self.openMaterialSpaces = config.getParameter("openMaterialSpaces", {})
end
