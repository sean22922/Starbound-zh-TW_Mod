function init()
  ObjectAddons:init(config.getParameter("addonConfig", {}), updateAnimationState)
end

function uninit()
  ObjectAddons:uninit()
end

function updateAnimationState()
  local isConnected = ObjectAddons:isConnectedAsAny()
  if isConnected and not storage.connected then
    animator.setAnimationState("connection", "connect")
  elseif storage.connected then
    animator.setAnimationState("connection", "connected")
  else
    animator.setAnimationState("connection", "disconnected")
  end
  storage.connected = isConnected
end
