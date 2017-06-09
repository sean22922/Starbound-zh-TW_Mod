function init()
  local acceptItems = config.getParameter("acceptItems")
  local sellFactor = config.getParameter("sellFactor")
  self.itemValues = {}
  for _, itemName in pairs(acceptItems) do
    local itemConfig = root.itemConfig(itemName)
    if itemConfig.config.price and itemConfig.config.price > 0 then
      self.itemValues[itemName] = math.ceil(itemConfig.config.price * sellFactor)
    end
  end
end

function update(dt)
  widget.setText("lblMoney", valueOfContents())
end

function triggerShipment(widgetName, widgetData)
  world.sendEntityMessage(pane.containerEntityId(), "triggerShipment")
  local total = valueOfContents()
  if total > 0 then
    player.giveItem({name = "money", count = total})
  end
  pane.dismiss()
end

function valueOfContents()
  local value = 0
  local allItems = widget.itemGridItems("itemGrid")
  for _, item in pairs(allItems) do
    value = value + (self.itemValues[item.name] or 0) * item.count
  end
  return value
end
