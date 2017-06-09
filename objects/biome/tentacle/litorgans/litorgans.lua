function init()
  object.setLightColor({0, 0, 0})
end

function notify(notification)
  if notification.type == "lightup" then
    object.setLightColor(config.getParameter("lightColor"))
    return true
  end
end
