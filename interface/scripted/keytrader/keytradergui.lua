require "/scripts/util.lua"

function init()
  widget.setItemSlotItem("itmKey", "vaultkey")

  self.tradeOptions = config.getParameter("tradeOptions")

  self.seed = status.statusProperty("vaultKeySeed")
  if not self.seed then
    setNewSeed()
  end

  setupTrade()
end

function update(dt)
  local playerItemCount = player.hasCountOfItem(self.tradeItem)
  local canTrade = playerItemCount >= self.tradeCount
  local directive = canTrade and "^green;"or"^red;"
  if playerItemCount > 99 then
    playerItemCount = "99+"
  end
  widget.setText("lblTradeItemQuantity", string.format("%s%s/%s", directive, playerItemCount, self.tradeCount))
  widget.setButtonEnabled("btnTrade", canTrade)
end

function setNewSeed()
  self.seed = util.seedTime()
  status.setStatusProperty("vaultKeySeed", self.seed)
end

function setupTrade()
  local tradeOption = self.tradeOptions[sb.staticRandomI32Range(1, #self.tradeOptions, self.seed)]
  self.tradeItem = tradeOption[1]
  self.tradeCount = tradeOption[2]
  widget.setItemSlotItem("itmTradeItem", self.tradeItem)

  local tradeItemConfig = root.itemConfig(self.tradeItem)
  widget.setText("lblTradeItemName", tradeItemConfig.config.shortdescription)

  update()
end

function tradeForKey()
  if player.consumeItem({self.tradeItem, self.tradeCount}) then
    player.giveItem("vaultkey")
    setNewSeed()
    setupTrade()
  end
end
