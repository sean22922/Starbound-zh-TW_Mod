require "/scripts/quest/participant.lua"
require "/scripts/quest/location.lua"
require "/scripts/stagehandutil.lua"
require "/scripts/spawnPoint.lua"

function init()
  if not entity.uniqueId() then
    stagehand.setUniqueId(sb.makeUuid())
  end

  self.region = translateBroadcastArea()

  local locationType = config.getParameter("locationType")
  assert(locationType ~= nil)
  self.location = Location.new(entity.uniqueId(), locationType, self.region, storage.locationTags)
  if not storage.locationTags then
    storage.locationTags = self.location.tags
    storage.regionModified = false
    self.location:register()
  end

  self.integrityCheck = util.interval(config.getParameter("integrityCheckCooldown"), checkIntegrity, 0)

  local questOutbox = Outbox.new("questOutbox", ContactList.new("questContacts"))
  self.quest = QuestParticipant.new("quest", questOutbox)
end

function uninit()
  self.quest:uninit()
end

function update(dt)
  self.quest:update()

  if not storage.regionModified then
    self.integrityCheck(dt)
  end

  if not storage.regionModified then
    if self.location:isRegistered() and self.quest:hasQuest() then
      self.location:unregister()
    elseif not self.location:isRegistered() and not self.quest:hasQuest() then
      self.location:register()
    end

  elseif not self.quest:hasActiveQuest() then
    util.debugLog("Not registered and have no quests. Dying")
    self.location:unregister()
    self.quest:die()
    stagehand.die()
  end
end

function checkIntegrity()
  if world.isPlayerModified(self.region) then
    util.debugLog("questlocation %s region has been modified by player", entity.uniqueId())
    storage.regionModified = true
    self.location:unregister()
  end
end

function findPosition(boundBox)
  return findSpaceInRect(self.region, boundBox)
end

function containerHasSpace(entityId, numSlots)
  -- Gives false negatives on mostly-full chests because it doesn't check if
  -- the new items can stack.
  for i = 0, world.containerSize(entityId)-1 do
    local slot = world.containerItemAt(entityId, i)
    if not slot or slot.count == 0 then
      numSlots = numSlots - 1
      if numSlots <= 0 then
        return true
      end
    end
  end
  return false
end

function findChestWithSpace(objectTypes, treasure)
  local objects = world.objectQuery({self.region[1], self.region[2]}, {self.region[3], self.region[4]})
  for _,entityId in pairs(objects) do
    if not contains(objectTypes, world.entityName(entityId)) then return nil end
    if not containerHasSpace(entityId, #treasure) then return nil end
    return entityId
  end
end

function addTreasure(treasurePool)
  local objectTypes = config.getParameter("treasureChests", {"treasurechest"})
  local treasure = root.createTreasure(treasurePool, world.threatLevel())
  local chest = findChestWithSpace(objectTypes, treasure)
  if chest then
    for _,item in pairs(treasure) do
      local overflow = world.containerAddItems(chest, item)
      if overflow then
        world.spawnItem(overflow.name, world.entityPosition(chest), overflow.count, overflow.parameters)
      end
    end
    return true
  end

  local position = findSpaceInRect(self.region, {-1, 0, 1, 2})
  if not position then return false end
  local objectType = objectTypes[math.random(#objectTypes)]
  return world.placeObject(objectType, position, nil, {
      treasurePools = {treasurePool}
    })
end
