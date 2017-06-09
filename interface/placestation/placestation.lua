require "/interface/cockpit/cockpitview.lua"
require "/interface/cockpit/cockpitutil.lua"

-- engine callbacks
function init()
  View:init()

  self.clickEvents = {}

  self.state = FSM:new()
  self.state:set(connectState)

  self.system = celestial.currentSystem()

  self.sounds = config.getParameter("sounds")

  self.padding = root.assetJson("/systemworld.config:clientObjectSpawnPadding")
  -- extra padding to give some wiggle room
  self.extraPadding = config.getParameter("extraOrbitPadding")

  pane.playSound(self.sounds.open)
end

function dismissed()
  for soundName,sound in pairs(self.sounds) do
    if soundName ~= "success" then
      pane.stopAllSounds(sound)
    end
  end
end

function update(dt)
  self.canvasFocused = widget.hasFocus("consoleScreenCanvas")

  if not world.sendEntityMessage(player.id(), "holdingTransponder"):result() then
    pane.dismiss()
  end

  if not compare(self.system, celestial.currentSystem()) then
    self.state:set(connectState)
  end

  self.state:update(dt)
end

function toggleConfigure()
  pane.playSound(self.sounds.configure)
  widget.setVisible("configure", true)
  widget.focus("configure.name")
end

function configurationChanged()
  -- play every other change
  self.play = not self.play
  if self.play then
    pane.playSound(self.sounds.typing)
  end
end

function saveConfiguration()
  local name = widget.getText("configure.name")
  local description = widget.getText("configure.description")
  if name ~= "" and description ~= "" then
    self.configuration = {
      name = name,
      description = description
    }
    self.configuration.name = widget.getText("configure.name")
    self.configuration.description = widget.getText("configure.description")
    widget.setVisible("configure", false)
    widget.setVisible("toggleConfigure", true)

    widget.setVisible("nameLabel", true)
    widget.setText("nameLabel", config.getParameter("nameLabel")..name)

    widget.setVisible("descriptionLabel", true)
    widget.setText("descriptionLabel", config.getParameter("descriptionLabel")..description)
    widget.focus("consoleScreenCanvas")
  end
end

function canvasClickEvent(position, button, isButtonDown)
  if self.canvasFocused then
    table.insert(self.clickEvents, {position, button, isButtonDown})
  end
end

function takeInputEvents()
  local clicks = self.clickEvents
  self.clickEvents = {}
  return clicks
end

-- states
function connectState()
  local dotCycle = config.getParameter("dotCycle")
  widget.setVisible("coordinateLabel", false);

  local connect = config.getParameter("connect")

  local dotTimer = 0.0
  local dots = function()
    local d = ""
    for i = 1, math.floor(dotTimer / (dotCycle / 4)) do
      d = d .. "."
    end
    return d
  end
  util.wait(connect.connectTime, function()
    dotTimer = (dotTimer + script.updateDt()) % dotCycle
    widget.setText("connectingLabel", string.format("%s%s", connect.connectText, dots()))
  end)

  if player.worldId() == player.ownShipWorldId() then
    local system = celestial.currentSystem()
    local planets = {}

    util.wait(connect.successTime, function()
      dotTimer = (dotTimer + script.updateDt()) % dotCycle
      widget.setText("connectingLabel", string.format("%s\n%s%s", connect.connectText, connect.successText, dots()))

      planets = celestial.children(system)
    end)
    while #celestial.children(system) == 0 do
      coroutine.yield()
    end
    widget.setText("connectingLabel", config.getParameter("connectedText"))
    self.state:set(placeState, system, planets)
  else
    pane.playSound(self.sounds.error)
    widget.setText("connectingLabel", string.format("%s\n%s", connect.connectText, connect.failText))
    while true do
      coroutine.yield()
    end
  end
end

function placeState(system, planets)
  widget.setVisible("configure", true)
  widget.focus("configure.name")
  widget.setVisible("coordinateLabel", true);
  local coordinateText = config.getParameter("coordinateText")
  local connectedText = config.getParameter("connectedText")

  View:reset()
  View:setCamera("system", {0, 0}, View:systemScale(system))

  local dotTimer = 0
  local lastValid = false
  while true do
    dotTimer = (dotTimer + script.updateDt()) % 0.5
    local dot = dotTimer > (0.5 / 2) and "." or ""
    widget.setText("connectingLabel", connectedText .. dot)
    View.canvas:clear()

    local mousePos = View:mousePosition()
    local selectPosition = View:toSystem(mousePos)
    widget.setText("coordinateLabel", string.format(coordinateText, math.floor(selectPosition[1]), math.floor(selectPosition[2])))

    local selectDistance = vec2.mag(selectPosition)
    local validDistance = true

    local color = {150, 150, 150}
    local starSize = celestial.planetSize(system) / 2

    if selectDistance < starSize + self.padding + self.extraPadding then
      validDistance = false
    end

    local maxOrbit = 0
    for _,planet in pairs(planets) do
      local orbit = vec2.mag(celestial.planetPosition(planet))
      local width = (celestial.clusterSize(planet) / 2)
      if orbit + width + (self.padding * 2) > maxOrbit then
        maxOrbit = orbit + width + (self.padding * 2)
      end
      if math.abs(selectDistance - orbit) < width + self.padding + self.extraPadding then
        validDistance = false
      end
    end

    if selectDistance > maxOrbit then
      validDistance = false
    end

    for _,uuid in pairs(celestial.systemObjects()) do
      local objectConfig = celestial.objectTypeConfig(celestial.objectType(uuid))
      if objectConfig.permanent then
        local orbit = vec2.mag(celestial.objectPosition(uuid))
        if math.abs(selectDistance - orbit) < self.padding + self.extraPadding then
          validDistance = false
        end
      end
    end

    renderOrbits(system, planets, celestial.systemObjects(), self.padding + self.extraPadding, true)
    if self.configuration and self.canvasFocused then
      renderSelection(mousePos, selectDistance, validDistance)
      if not lastValid and validDistance then
        pane.playSound(self.sounds.valid)
      end
    end
    lastValid = validDistance

    for _,click in pairs(takeInputEvents()) do
      if self.configuration then
        local position, button, down = click[1], click[2], click[3]
        if button == 0 and down and validDistance then
          return self.state:set(deployState, system, planets, selectPosition)
        end
      end
    end

    coroutine.yield()
  end
end

function deployState(system, planets, deployPosition)
  widget.setVisible("toggleConfigure", false)

  local sequence = config.getParameter("deploySequence")
  local sequenceText = config.getParameter("deployingText")
  local dotCycle = config.getParameter("dotCycle")
  local objectRect = config.getParameter("objectRect")

  local orbit = vec2.mag(deployPosition) * View.systemCamera.scale
  local points = 4 * math.sqrt(orbit)

  local dotTimer = 0.0
  local dots = function()
    local d = ""
    for i = 1, math.floor(dotTimer / (dotCycle / 4)) do
      d = d .. "."
    end
    return d
  end
  pane.playSound(self.sounds.dispatch, -1)
  util.wait(sequence.dispatching, function()
    View.canvas:clear()
    dotTimer = (dotTimer + script.updateDt()) % dotCycle
    widget.setText("connectingLabel", sequenceText.dispatching .. dots())

    View.canvas:clear()
    renderOrbits(system, planets, celestial.systemObjects(), self.padding + self.extraPadding, false)
    View.canvas:drawPoly(circle(orbit, points, View:sToScreen({0, 0})), {0, 255, 0})
  end)
  pane.stopAllSounds(self.sounds.dispatch)

  local probeStart = vec2.withAngle(math.random() * math.pi * 2, View.settings.viewRadius * 2 / View.systemCamera.scale)
  local timer = 0
  pane.playSound(self.sounds.launch, -1)
  util.wait(sequence.traveling, function()
    timer = timer + script.updateDt()
    View.canvas:clear()
    dotTimer = (dotTimer + script.updateDt()) % dotCycle
    widget.setText("connectingLabel", sequenceText.traveling .. dots())

    View.canvas:clear()
    renderOrbits(system, planets, celestial.systemObjects(), self.padding + self.extraPadding, false)

    View.canvas:drawPoly(circle(orbit, points, View:sToScreen({0, 0})), {0, 255, 0})
    local ratio = 1 - ((1 - (timer / sequence.traveling)) ^ 2)
    local pos = vec2.add(probeStart, vec2.mul(vec2.sub(deployPosition, probeStart), ratio))
    View.canvas:drawRect(rect.translate(objectRect, View:sToScreen(pos)), "white")
  end)
  pane.stopAllSounds(self.sounds.launch)

  timer = 0
  local lastRatio = 1
  local uuid = nil
  local deployed = false
  local blinkTime = config.getParameter("deployBlinkTime")
  while true do
    timer = timer + script.updateDt()
    dotTimer = (dotTimer + script.updateDt()) % dotCycle
    widget.setText("connectingLabel", sequenceText.deploying .. dots())

    View.canvas:clear()
    renderOrbits(system, planets, celestial.systemObjects(), self.padding + self.extraPadding, false)

    View.canvas:drawRect(rect.translate(objectRect, View:sToScreen(deployPosition)), "white")


    local ratio = (timer / blinkTime) % 1.0
    ratio = 1 - ((1 - ratio) ^ 2)

    -- play deploy sound each time the timer loops
    if ratio < lastRatio then
      pane.playSound(self.sounds.deploy)
    end
    lastRatio = ratio

    local orbit = 20 * ratio
    View.canvas:drawPoly(circle(orbit, 4 * math.sqrt(orbit), View:sToScreen(deployPosition)), {255, 255, 255, (1 -ratio) * 255}, 0.5)

    if timer > sequence.deploying then
      if not deployed then
        local parameters = {
          displayName = self.configuration.name,
          description = self.configuration.description
        }
        uuid = celestial.systemSpawnObject("playerstation", deployPosition, nil, parameters)
        deployed = true
      end

      if uuid and celestial.objectPosition(uuid) ~= nil then
        world.sendEntityMessage(player.id(), "setTransponderConsumed")
        break
      end
    end

    if timer > sequence.deployFailure then
      break
    end
    coroutine.yield()
  end

  if uuid and celestial.objectPosition(uuid) ~= nil then
    pane.playSound(self.sounds.complete)
    pane.playSound(self.sounds.success)

    widget.setText("connectingLabel", sequenceText.deployed)
    util.wait(2.0, function()
      View.canvas:clear()
      renderOrbits(system, planets, celestial.systemObjects(), self.padding + self.extraPadding, false)
    end)

    world.sendEntityMessage(player.id(), "consumeTransponder")
    while true do
      coroutine.yield()
    end
  else
    widget.setText("connectingLabel", sequenceText.error)
    widget.setFontColor("connectingLabel", config.getParameter("errorColor"))
    pane.playSound(self.sounds.error)
    util.wait(4.0, function()
      View.canvas:clear()
      renderOrbits(system, planets, celestial.systemObjects(), self.padding + self.extraPadding, false)
      View.canvas:drawPoly(circle(orbit, points, View:sToScreen({0, 0})), {255, 0, 0})
    end)
    pane.dismiss()
    coroutine.yield()
  end
end

function renderOrbits(system, planets, objects, padding, withDeadzones)
  local objectRect = config.getParameter("objectRect")

  local color = {150, 150, 150}
  local starSize = celestial.planetSize(system) / 2 + self.padding + self.extraPadding
  View.canvas:drawTriangles(fillCircle(starSize * View.systemCamera.scale, 20, View:sToScreen({0, 0})), color)

  for _,planet in pairs(planets) do
    local planetPosition = celestial.planetPosition(planet)
    local size = celestial.planetSize(planet) / 2
    local orbit = vec2.mag(planetPosition) * View.systemCamera.scale
    local width = celestial.clusterSize(planet) + padding * 2
    if withDeadzones then
      View.canvas:drawTriangles(wideCircle(orbit, 5 * math.sqrt(orbit), width * View.systemCamera.scale, View:sToScreen({0, 0})), {40, 0, 0, 255})
    end
    View.canvas:drawPoly(poly.translate(circle(orbit, 4 * math.sqrt(orbit)), View:sToScreen({0, 0})), color, 1.0)
    View.canvas:drawTriangles(fillCircle(size * View.systemCamera.scale, 12, View:sToScreen(planetPosition)), color)

    for _,moon in pairs(celestial.children(planet)) do
      local size = celestial.planetSize(moon) / 2
      local moonPosition = celestial.planetPosition(moon)
      local orbit = vec2.mag(vec2.sub(moonPosition, planetPosition)) * View.systemCamera.scale
      View.canvas:drawPoly(poly.translate(circle(orbit, 4 * math.sqrt(orbit)), View:sToScreen(planetPosition)), color, 0.5)
      View.canvas:drawTriangles(fillCircle(size, 6, View:sToScreen(celestial.planetPosition(moon))), color)
    end
  end

  for _,uuid in pairs(celestial.systemObjects()) do
    local objectConfig = celestial.objectTypeConfig(celestial.objectType(uuid))
    if objectConfig.permanent then
      local position = celestial.objectPosition(uuid)
      local orbit = vec2.mag(position) * View.systemCamera.scale
      local width = padding * 2
      if withDeadzones then
        View.canvas:drawTriangles(wideCircle(orbit, 5 * math.sqrt(orbit), width * View.systemCamera.scale, View:sToScreen({0, 0})), {40, 0, 0, 255})
      end
      View.canvas:drawPoly(poly.translate(circle(orbit, 4 * math.sqrt(orbit)), View:sToScreen({0, 0})), "white", 0.5)
      View.canvas:drawRect(rect.translate(objectRect, View:sToScreen(position)), "white")
    end
  end
end

function renderSelection(mousePos, selectDistance, validSelection)
  local objectRect = config.getParameter("objectRect")

  local color
  if validSelection then
    color = {0, 255, 0, 255}
  else
    color = {255, 0, 0, 255}
  end
  View.canvas:drawPoly(circle(selectDistance * View.systemCamera.scale, 40, View:sToScreen({0, 0})), color, 1.0)
  View.canvas:drawLine({0, mousePos[2]}, {View.windowSize[1], mousePos[2]}, {255, 255, 255, 255})
  View.canvas:drawLine({mousePos[1], 0}, {mousePos[1], View.windowSize[2]}, {255, 255, 255, 255})
  View.canvas:drawRect(rect.translate(objectRect, mousePos), "white")
end
