require "/scripts/stagehandutil.lua"
require "/scripts/rect.lua"
require "/scripts/util.lua"

function init()
end

function update(dt)
  local area = translateBroadcastArea()
  if world.regionActive(area) then
    local objects = world.entityQuery(rect.ll(area), rect.ur(area), { includedTypes = {"object"} })
    if self.objects then
      local removed = util.filter(util.keys(self.objects), function(objectId) return not contains(objects, objectId) end)
      if #removed > 0 then
        for _,brokenId in pairs(removed) do
          broadcastObjectBroken(self.objects[brokenId])
        end
        setObjects(objects)
      end
    else
      setObjects(objects)
    end
  end
end

function setObjects(objectIds)
  self.objects = {}
  for _,objectId in pairs(objectIds) do
    self.objects[objectId] = world.entityPosition(objectId)
  end
end

function broadcastObjectBroken(position)
  local area = translateBroadcastArea()

  local players = world.entityQuery(rect.ll(area), rect.ur(area), { includedTypes = {"player"}})
  if #players > 0 then
    table.sort(players, function(a,b)
      return world.magnitude(world.entityPosition(a), position) < world.magnitude(world.entityPosition(b), position)
    end)
    local notification = {
      type = "objectBroken",
      sourceId = entity.id(),
      targetPosition = position,
      targetId = players[1]
    }
    local npcs = world.entityQuery(rect.ll(area), rect.ur(area), { includedTypes = {"npc"} })
    for _,npcId in pairs(npcs) do
      if world.entityDamageTeam(npcId).team == 1 then
        world.sendEntityMessage(npcId, "notify", notification)
      end
    end
  end
end
