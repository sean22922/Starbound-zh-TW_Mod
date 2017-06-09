require "/scripts/stagehandutil.lua"

function init()
  self.containsPlayers = {}
  self.messageType = config.getParameter("messageType")
  self.messageArgs = config.getParameter("messageArgs", {})
  if type(self.messageArgs) ~= "table" then
    self.messageArgs = {self.messageArgs}
  end
end

function update(dt)
  local newPlayers = broadcastAreaQuery({ includedTypes = {"player"} })
  local oldPlayers = table.concat(self.containsPlayers, ",")
  for _, id in pairs(newPlayers) do
    if not string.find(oldPlayers, id) then
      world.sendEntityMessage(id, self.messageType, table.unpack(self.messageArgs))
    end
  end
  self.containsPlayers = newPlayers
end
