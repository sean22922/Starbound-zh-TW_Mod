function init()
  self.outbox = Outbox.new("outbox", ContactList.new("contacts"))
end

function uninit()
  self.outbox:uninit()
end

function update()
  self.outbox:update()

  if self.outbox:empty() then
    stagehand.die()
  end
end

function post(contacts, messages)
  self.outbox.contactList:registerContacts(contacts)
  for _,messageData in ipairs(messages) do
    self.outbox:logMessage(messageData, "mailbox received")
    self.outbox:postpone(messageData)
  end
end
