function init()
  self.placed = true
end

function update(dt)
  if self.placed then
    world.spawnMonster(config.getParameter("monsterType"), object.position())
    object.smash()
  end
end
