require "/interface/games/util.lua"
Sprite = {}

function Sprite:new(image, size, dimensions, frames)
  local newSprite = {
    image = image,
    size = size or root.imageSize(image),
    origin = {0,0},
    dimensions = dimensions or {1,1},
    scale = 1,
    color = {255,255,255,255},

    cell = 0,
    frames = frames or 1,
    loop = true,
    timer = 0
  }
  setmetatable(newSprite, extend(self))
  return newSprite
end

function Sprite:setCell(i)
  self.cell = i
end

function Sprite:fitToBox(boxSizeX,boxSizeY)
  self.scale=math.min(boxSizeX/self.size[1], boxSizeY/self.size[2])
end

function Sprite:draw(position)
  local x = self.cell % self.dimensions[1]
  local y = (self.cell - x) / self.dimensions[2]
  local texCoords = {x * self.size[1], y * self.size[2], (x+1) * self.size[1], (y+1) * self.size[2]}
  local quad = translateRect({position[1], position[2], position[1] + self.size[1] * self.scale, position[2] + self.size[2] * self.scale}, {-self.origin[1] * self.scale, -self.origin[2] * self.scale})
  gameCanvas:drawImageRect(self.image, texCoords, quad, self.color)
end
