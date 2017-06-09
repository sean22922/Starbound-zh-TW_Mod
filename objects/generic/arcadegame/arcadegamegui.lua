tiles = {
  {
    transparent = false,
    blocking = true,
    texture = {
      image = "/objects/generic/arcadegame/bricks.png",
      width = 64,
      height = 64,
      lighting = true
    }
  },
  {
    transparent = true,
    blocking = false,
    texture = {
      image = "/objects/generic/arcadegame/gate.png",
      width = 64,
      height = 64,
      lighting = true
    }
  },
  {
    transparent = true,
    blocking = true,
    texture = {
      image = "/objects/generic/arcadegame/window.png",
      width = 64,
      height = 64,
      lighting = true
    }
  },
  {
    transparent = false,
    blocking = true,
    texture = {
      image = "/objects/generic/arcadegame/outside.png",
      width = 64,
      height = 64,
      lighting = false
    }
  }
}

level = {
  width = 25,
  height = 25,
  tiles = {
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4,
    4, 1, 1, 1, 3, 1, 1, 1, 3, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 4,
    4, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 2, 0, 0, 0, 1, 0, 0, 1, 1, 1, 1, 0, 1, 4,
    4, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 4,
    4, 3, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 2, 1, 0, 0, 1, 0, 1, 4,
    4, 1, 0, 0, 0, 0, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 1, 4,
    4, 1, 1, 1, 1, 2, 1, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 4,
    4, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 4,
    4, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 1, 3, 1, 1, 1, 0, 1, 0, 1, 4,
    4, 1, 0, 0, 0, 1, 1, 3, 1, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 3, 1, 4,
    4, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 0, 1, 0, 1, 4,
    4, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 3, 0, 2, 4,
    4, 1, 0, 1, 1, 1, 0, 0, 0, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 0, 1, 0, 1, 4,
    4, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 1, 4,
    4, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 1, 2, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 4,
    4, 1, 0, 1, 0, 1, 2, 1, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 4,
    4, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 4,
    4, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 4,
    4, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 1, 0, 1, 4,
    4, 1, 0, 1, 1, 2, 1, 1, 1, 1, 0, 1, 1, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, 4,
    4, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 4,
    4, 1, 0, 2, 0, 0, 1, 2, 1, 1, 1, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 4,
    4, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 4,
    4, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 4,
    4, 4, 4, 4, 4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 4, 4, 4
  }
}

input = {
  key = {
    left = 90,
    right = 89,
    up = 87,
    down = 88,
    w = 65,
    a = 43,
    s = 61,
    d = 46
  },
  left = false,
  right = false,
  up = false,
  down = false
}

game = {
  gameover = false
}

function init()
  self.raycaster = createRayCaster(level, tiles)

  renderer.height = 158
  renderer.width = 293
  renderer.position = {0, 52}

  gameCanvas = widget.bindCanvas("scriptCanvas")
  widget.focus("scriptCanvas")
end

function update(dt)
  gameCanvas:clear()

  --Ground and sky background
  drawGround()
  drawSky()

  --Render walls
  self.raycaster:castRays(renderer.width, Player.position, Player.direction, function(x, ray, distance, realDistance, hit, side, textureX)
    renderer:drawWall(x, 1, distance, realDistance, tiles[hit].texture, side, textureX)
  end)

  renderer:render()

  drawGui()

  if not game.gameover then
    Player:update(dt, input)
  else
    gameCanvas:drawText("Congratulations, you escaped the dungeon!", {position = {25, 100}, width = 290, centered = true}, 15, {255, 255, 255, 255})
  end
end

function drawSky()
  -- gameCanvas:drawRect({0, renderer.height / 2, renderer.width, renderer.height}, {0, 0, 0})
  gameCanvas:drawImageRect("/objects/generic/arcadegame/sky.png", {0, 0, 64, 64}, {0 + renderer.position[1], renderer.height / 2 + renderer.position[2], renderer.width + renderer.position[1], renderer.height + renderer.position[2]})
end

function drawGround()
  -- gameCanvas:drawRect({0, 0, renderer.width, renderer.height / 2}, {0, 20, 0})
  gameCanvas:drawImageRect("/objects/generic/arcadegame/ground.png", {0, 0, 64, 64}, {0 + renderer.position[1], 0 + renderer.position[2], renderer.width + renderer.position[1], renderer.height / 2 + renderer.position[2]})
end

function drawGui()
  gameCanvas:drawImage("/objects/generic/arcadegame/gui.png", {0, 0})
end

function index(x, y)
  return ((level.height - 1 - y) * level.width) + x + 1
end

function collidableTile(tilePos)
  local tile = level.tiles[index(tilePos[1], tilePos[2])]
  if tile ~= nil and tile ~= 0 and tiles[tile].blocking then
    return tile
  else
    return false
  end
end

function canvasClickEvent(position, button, isButtonDown)
end

function canvasKeyEvent(key, isKeyDown)
  if key == input.key.right or key == input.key.d then
    input.right = isKeyDown
  end
  if key == input.key.left or key == input.key.a then
    input.left = isKeyDown
  end
  if key == input.key.up or key == input.key.w then
    input.up = isKeyDown
  end
  if key == input.key.down or key == input.key.s then
    input.down = isKeyDown
  end
end

Player = {
  position = {16.5, 11},
  direction = math.pi / 3,
  size = 0.5,
  color = {50, 50, 150},
  speed = 2
}

function Player:update(dt, input)
  if input.left then
    self.direction = self.direction + 0.05
  end
  if input.right then
    self.direction = self.direction - 0.05
  end
  if input.up or input.down then
    local move = vec2.mul({math.cos(self.direction), math.sin(self.direction)}, self.speed * dt)
    if input.up then
      self.position[1] = Player.position[1] + move[1]
      self.position[2] = Player.position[2] + move[2]
    end
    if input.down then
      self.position[1] = self.position[1] - move[1]
      self.position[2] = self.position[2] - move[2]
    end
  end

  --Collide with walls
  local boundBox = {
    self.position[1] - self.size / 2, self.position[2] - self.size / 2,
    self.position[1] + self.size / 2, self.position[2] + self.size / 2
  }
  local tilePos = {math.floor(self.position[1]), math.floor(self.position[2])}

  local collidedWith

  local westTile = collidableTile({tilePos[1] - 1, tilePos[2]})
  if westTile and boundBox[1] < tilePos[1] then
    self.position[1] = tilePos[1] + self.size / 2
    collidedWith = westTile
  end

  local eastTile = collidableTile({tilePos[1] + 1, tilePos[2]})
  if eastTile and boundBox[3] > tilePos[1] + 1 then
    self.position[1] = tilePos[1] + 1 - self.size / 2
    collidedWith = eastTile
  end

  local southTile = collidableTile({tilePos[1], tilePos[2] - 1})
  if southTile and boundBox[2] < tilePos[2] then
    self.position[2] = tilePos[2] + self.size / 2
    collidedWith = southTile
  end

  local northTile = collidableTile({tilePos[1], tilePos[2] + 1})
  if northTile and boundBox[4] > tilePos[2] + 1 then
    self.position[2] = tilePos[2] + 1 - self.size / 2
    collidedWith = northTile
  end

  if collidedWith then
    if collidedWith == 4 then
      game.gameover = true
      world.sendEntityMessage(pane.sourceEntity(), "youwin")
    end
  end
end
