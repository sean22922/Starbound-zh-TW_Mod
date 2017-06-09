require "/scripts/stagehandutil.lua"

function init()
  self.players = {}
  self.music = config.getParameter("music", {})
  self.musicEnabled = false
end

function update(dt)
  for playerId, _ in pairs(self.players) do
    if not world.entityExists(playerId) then
      -- Player died or left the mission
      self.players[playerId] = nil
    end
  end

  local newPlayers = broadcastAreaQuery({ includedTypes = {"player"} })
  for _, playerId in pairs(newPlayers) do
    if not self.players[playerId] then
      playerEnteredBattle(playerId)
      self.players[playerId] = true
    end
  end
end

function playerEnteredBattle(playerId)
  if self.musicEnabled then
    world.sendEntityMessage(playerId, "playAltMusic", self.music, config.getParameter("fadeInTime"))
  else
    world.sendEntityMessage(playerId, "playAltMusic", jarray(), config.getParameter("startFadeOutTime"))
  end
end

function startMusic()
  for playerId, _ in pairs(self.players) do
    world.sendEntityMessage(playerId, "playAltMusic", self.music, config.getParameter("fadeInTime"))
  end
end

function stopMusic()
  for playerId, _ in pairs(self.players) do
    world.sendEntityMessage(playerId, "playAltMusic", jarray(), config.getParameter("endFadeOutTime"))
  end
end

function setMusicEnabled(state)
  if self.musicEnabled ~= state then
    if state then
      startMusic()
    else
      stopMusic()
    end
    self.musicEnabled = state
  end
end
