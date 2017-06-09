require('/scripts/messageutil.lua')

local handlerConstructors = {}

function buildMessageHandlers()
  for _, handlerInfo in pairs(config.getParameter("messageHandlers", {})) do
    local messageType = handlerInfo.messageType
    local handler = handlerConstructors[handlerInfo.handler](table.unpack(handlerInfo.handlerArgs))
    message.setHandler(messageType, handler)
  end
end

local function offerWarp(warpAction, dialogConfig, portrait)
  dialogConfig = root.assetJson(dialogConfig)
  if portrait and dialogConfig.images then
    dialogConfig.images.portrait = portrait
  end
  promises:add(player.confirm(dialogConfig), function (confirmed)
      if confirmed then
        player.warp(warpAction, "beam")
      end
    end)
end

function handlerConstructors.fixedWarpOffer(warpAction, dialogConfig, portrait)
  return function ()
    if type(portrait) == "string" then
      local portraitParam = quest.parameters()[portrait]
      portrait = nil
      if portraitParam and portraitParam.portrait then
        portrait = portraitParam.portrait
      end
    end
    offerWarp(warpAction, dialogConfig, portrait)
  end
end

function handlerConstructors.warpOffer()
  return function (_, _, warpAction, dialogConfig, portrait)
    offerWarp(warpAction, dialogConfig, portrait)
  end
end
