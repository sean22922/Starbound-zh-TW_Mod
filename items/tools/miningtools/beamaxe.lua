function init()
  self.radius = config.getParameter("blockRadius") / 2
  self.altRadius = config.getParameter("altBlockRadius") / 2

  self.notifyTime = config.getParameter("notifyEntityTime")
  self.notifyTimer = 0
  self.notifyDamage = config.getParameter("tileDamage") / config.getParameter("fireTime") * self.notifyTime
  self.notifyQueryParams = {
    includedTypes = {"vehicle"},
    boundMode = "position"
  }
end

function update(dt, fireMode, shifting)
  if fireMode == "primary" then
    self.notifyTimer = math.max(0, self.notifyTimer - dt)
    if self.notifyTimer == 0 then
      self.notifyTimer = self.notifyTime
      notifyEntities(shifting)
    end
  else
    self.notifyTimer = 0
  end
end

function notifyEntities(shifting)
  local entities = world.entityQuery(fireableItem.ownerAimPosition(), shifting and self.altRadius or self.radius, self.notifyQueryParams)
  for _, entityId in ipairs(entities) do
    world.sendEntityMessage(entityId, "positionTileDamaged", self.notifyDamage)
  end
end
