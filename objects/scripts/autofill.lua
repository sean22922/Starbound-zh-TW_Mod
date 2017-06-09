function init()
  self.autofillContents = config.getParameter("autofillContents", {})
end

function update(dt)
  for i, item in ipairs(self.autofillContents) do
    local numberAvailable = world.containerAvailable(entity.id(), item.name)
    if numberAvailable < item.count then
      newItem = {
        name = item.name,
        count = item.count - numberAvailable,
        parameters = item.parameters or {}
      }
      world.containerAddItems(entity.id(), newItem)
    end
  end
end
