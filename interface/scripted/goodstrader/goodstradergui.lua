require "/scripts/util.lua"

function init()
  self.baseBuyFactor = config.getParameter("baseBuyFactor")
  self.baseSellFactor = config.getParameter("baseSellFactor")
  self.buyFactor = config.getParameter("buyFactor")
  self.sellFactor = config.getParameter("sellFactor")
  self.buyExponent = config.getParameter("buyExponent")
  self.sellExponent = config.getParameter("sellExponent")
  self.buyItem = config.getParameter("buyItem")
  self.sellItem = config.getParameter("sellItem")

  self.sellItemConfig = root.itemConfig(self.sellItem)
  widget.setItemSlotItem("itmSellItem", self.sellItem)
  widget.setText("lblSellItemName", self.sellItemConfig.config.shortdescription)

  self.buyItemConfig = root.itemConfig(self.buyItem)
  widget.setItemSlotItem("itmBuyItem", self.buyItem)
  widget.setText("lblBuyItemName", self.buyItemConfig.config.shortdescription)

  updatePrices()
end

function update()
  widget.setButtonEnabled("btnBuy", player.currency("money") >= self.buyPrice)
  widget.setButtonEnabled("btnSell", player.hasItem(self.sellItem))
end

function buyGoods()
  if player.consumeCurrency("money", self.buyPrice) then
    player.giveItem(self.buyItem)
    self.buyFactor = self.buyFactor ^ self.buyExponent
    world.sendEntityMessage(pane.sourceEntity(), "onGoodsBuy")
    updatePrices()
  end
end

function sellGoods()
  if player.consumeItem(self.sellItem) then
    player.addCurrency("money", self.sellPrice)
    self.sellFactor = self.sellFactor ^ self.sellExponent
    world.sendEntityMessage(pane.sourceEntity(), "onGoodsSell")
    updatePrices()
  end
end

function updatePrices()
  self.buyPrice = math.floor((self.buyItemConfig.config.price or 0) * self.buyFactor)
  widget.setText("lblBuyPrice", labelColorDirective(self.baseBuyFactor, self.buyFactor) .. self.buyPrice)

  self.sellPrice = math.floor((self.sellItemConfig.config.price or 0) * self.sellFactor)
  widget.setText("lblSellPrice", labelColorDirective(self.baseSellFactor, self.sellFactor) .. self.sellPrice)
end

function labelColorDirective(baseFactor, currentFactor)
  local ratio = 1.0 - (currentFactor - 1.0) / (baseFactor - 1.0)
  local colorValue = math.floor(255 * ratio)
  return string.format("^#%02XFF%02X;", colorValue, colorValue)
end
