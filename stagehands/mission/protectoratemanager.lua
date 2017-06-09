require "/scripts/rect.lua"

function init()
  self.containsPlayers = {}
  self.broadcastArea = rect.translate(config.getParameter("broadcastArea", {-8, -8, 8, 8}), entity.position())
  self.signalRegion = rect.translate(config.getParameter("signalRegion", {-8, -8, 8, 8}), entity.position())

  message.setHandler("midpointSwitch", function(...)
      local beamaxeSearchArea = rect.translate({360, -10, 400, 10}, entity.position())
      world.objectQuery(rect.ll(beamaxeSearchArea), rect.ur(beamaxeSearchArea), {callScript = "showBeamaxe"})
      local propsSearchArea = rect.translate({300, -50, 460, 50}, entity.position())
      world.objectQuery(rect.ll(propsSearchArea), rect.ur(propsSearchArea), {callScript = "setDestroyed"})
      local npcSearchArea = rect.translate({200, -50, 360, 50}, entity.position())
      world.npcQuery(rect.ll(npcSearchArea), rect.ur(npcSearchArea), {callScript = "status.setResource", callScriptArgs = {"health", 0}})
      world.setSkyTime(config.getParameter("badTime"))
      world.setProperty("nonCombat", false)
    end)

  message.setHandler("setSpecies", function(_, _, species) self.species = species end)

  world.setSkyTime(config.getParameter("goodTime"))

  self.hasUpdatedShip = false

  -- sb.logInfo("Initializing protectorate manager with broadcastArea %s", self.broadcastArea)
end

function update(dt)
  world.loadRegion(self.signalRegion)
  queryPlayers()

  if self.species and not self.hasUpdatedShip then
    local shipSearchArea = rect.translate({800, -50, 900, 50}, entity.position())
    local ships = world.objectQuery(rect.ll(shipSearchArea), rect.ur(shipSearchArea), {callScript = "setSpecies", callScriptArgs = {self.species}})
    self.hasUpdatedShip = #ships > 0
  end
end

function queryPlayers()
  local newPlayerList = world.entityQuery(rect.ll(self.broadcastArea), rect.ur(self.broadcastArea), {includedTypes = {"player"}})
  local newPlayers = {}
  for _, id in pairs(newPlayerList) do
    if not self.containsPlayers[id] then
      world.sendEntityMessage(id, "protectorateManagerId", entity.id())
    end
    newPlayers[id] = true
  end
  self.containsPlayers = newPlayers
end
