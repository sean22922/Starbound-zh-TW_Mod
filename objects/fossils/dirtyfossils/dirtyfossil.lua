require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  storage.levelData = storage.levelData or false

  local treasure = util.weightedRandom(config.getParameter("treasurePools"))
  if treasure.type == "rare" or treasure.type == "normal" then
    animator.setParticleEmitterActive("sparkle1", true)
    if treasure.type == "rare" then
      animator.setParticleEmitterActive("sparkle2", true)
    end
  end
  object.setConfigParameter("treasure", treasure)

  self.dropItems = {}
  self.smash = false

  message.setHandler("addDrop", function(_, _, item)
    table.insert(self.dropItems, item)

    -- Don't drop booby prize
    self.smash = true
  end)

  message.setHandler("smash", function(_, _)
    object.smash(self.smash)
  end)

  message.setHandler("setInUse", function(_, _, inUse)
    object.setConfigParameter("inUse", inUse)
  end)
end

function die()
  for _,item in pairs(self.dropItems) do
    world.spawnItem(item, vec2.add(object.position(), {0, 3}))
  end
end