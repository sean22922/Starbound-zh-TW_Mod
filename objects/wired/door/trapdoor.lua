function init()
  setupMaterialSpaces()
  object.setMaterialSpaces(self.closedMaterialSpaces)

  self.detectEntityTypes = config.getParameter("detectEntityTypes", {"player", "npc"})
  self.detectBoundMode = config.getParameter("detectBoundMode", "CollisionArea")
  local detectArea = config.getParameter("detectArea")
  local pos = object.position()
  if not detectArea then
    local boundBox = object.boundBox()
    self.detectArea = {
      {boundBox[1] + 0.25, boundBox[2] + 0.05},
      {boundBox[3] - 0.25, boundBox[4] + 0.25}
    }
  elseif type(detectArea[2]) == "number" then
    --center and radius
    self.detectArea = {
      {pos[1] + detectArea[1][1], pos[2] + detectArea[1][2]},
      detectArea[2]
    }
  elseif type(detectArea[2]) == "table" and #detectArea[2] == 2 then
    --rect corner1 and corner2
    self.detectArea = {
      {pos[1] + detectArea[1][1], pos[2] + detectArea[1][2]},
      {pos[1] + detectArea[2][1], pos[2] + detectArea[2][2]}
    }
  end

  self.stayClosedTime = config.getParameter("stayClosedTime", 0.5)
  self.stayOpenTime = config.getParameter("stayOpenTime", 0.5)

  self.state = false
  self.triggered = false

  self.closeTimer = 0
  self.openTimer = self.stayClosedTime

  object.setInteractive(false)
end

function update(dt)
  if self.state then
    if entityInArea() then
      self.closeTimer = self.stayOpenTime
    else
      self.closeTimer = math.max(0, self.closeTimer - dt)
    end

    if self.closeTimer == 0 then
      closeDoor()
    end
  else
    if not self.triggered and entityInArea() then
      self.triggered = true
    end

    if self.triggered then
      self.openTimer = math.max(0, self.openTimer - dt)
      if self.openTimer == 0 then
        openDoor()
      end
    end
  end
end

function closeDoor()
  if self.state ~= false then
    self.state = false
    self.triggered = false
    self.openTimer = self.stayClosedTime
    animator.playSound("close")
    animator.setAnimationState("doorState", "closing")
    object.setMaterialSpaces(self.closedMaterialSpaces)
  end
end

function openDoor()
  if not self.state then
    self.state = true
    self.closeTimer = self.stayOpenTime
    animator.playSound("open")
    animator.setAnimationState("doorState", "open")
    object.setMaterialSpaces(self.openMaterialSpaces)
  end
end

function entityInArea()
  local entityIds = world.entityQuery(self.detectArea[1], self.detectArea[2], {
        withoutEntityId = entity.id(),
        includedTypes = self.detectEntityTypes,
        boundMode = self.detectBoundMode
      })
  return #entityIds > 0
end

function setupMaterialSpaces()
  self.closedMaterialSpaces = config.getParameter("closedMaterialSpaces")
  if not self.closedMaterialSpaces then
    self.closedMaterialSpaces = {}
    for i, space in ipairs(object.spaces()) do
      table.insert(self.closedMaterialSpaces, {space, "metamaterial:door"})
    end
  end
  self.openMaterialSpaces = config.getParameter("openMaterialSpaces", {})
end
