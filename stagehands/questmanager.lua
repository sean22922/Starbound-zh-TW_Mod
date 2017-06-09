require("/scripts/quest/manager.lua")

function init()
  self.outbox = Outbox.new("outbox", ContactList.new("contacts"))

  local arc = loadQuestArcDescriptor(config.getParameter("quest.arc"))
  self.questManager = QuestManager.new("quest", self.outbox, arc)
end

function uninit()
  self.questManager:uninit()
end

function update()
  if not storage.participantsReserved then
    -- Send initial messages out to entities taking part in this quest
    local participants = config.getParameter("quest.participants")
    self.questManager:reserveParticipants(participants)
    storage.participantsReserved = true
  end

  self.questManager:update()

  if self.questManager:finished() and self.outbox:empty() then
    stagehand.die()
  end
end
