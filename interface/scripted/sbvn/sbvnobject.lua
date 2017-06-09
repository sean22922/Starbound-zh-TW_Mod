function init()
  self.interactData = config.getParameter("interactData")

  message.setHandler("saveState", function(_, _, state)
      storage.gameState = state
    end)
end

function onInteraction(args)
  self.interactData.gameState = storage.gameState
  return {"ScriptPane", self.interactData}
end
