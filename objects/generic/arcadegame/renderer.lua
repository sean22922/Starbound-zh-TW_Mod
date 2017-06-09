renderer = {
  drawQueue = {},
  width = 400,
  height = 210,
  position = {0, 0}
}

function renderer:drawWall(x, width, distance, realDistance, texture, side, textureX)
  table.insert(self.drawQueue, {type = "wall", distance = distance, args = {x, width, distance, realDistance, texture, side, textureX}})
end

function renderer:render()
  table.sort(self.drawQueue, function(a, b)
    return a.distance > b.distance
  end)

  for i,drawCall in ipairs(self.drawQueue) do
    if drawCall.type == "wall" then
      self:renderWall(table.unpack(drawCall.args))
    end
  end

  self.drawQueue = {}
end

function renderer:renderWall(x, width, distance, realDistance, texture, side, textureX)
  local wallHeight = (1 / distance) * self.height
  local textureScale = wallHeight / texture.height

  textureX = math.floor(textureX * texture.width)

  local yCenter = self.height / 2 + self.position[2]
  local screenCoords = {x + self.position[1], yCenter - wallHeight / 2, x + self.position[1] + width, yCenter + wallHeight / 2}

  local wallfade
  if texture.lighting then
    wallfade = math.max(0, 200 * (1 - realDistance / 6))
  else
    wallfade = 255
  end
  gameCanvas:drawImageRect(texture.image, {textureX, 0, textureX + 1, texture.height}, screenCoords, {wallfade, wallfade, wallfade, 255})
end
