function init()
  local detectArea = config.getParameter("detectArea")
  local pos = object.position()
  if type(detectArea[2]) == "number" then
    --center and radius
    self.detectArea = {
      {pos[1] + detectArea[1][1], pos[2] + detectArea[1][2]},
      detectArea[2]
    }
  elseif type(detectArea[2]) == "table" and #detectArea[2] == 2 then
    --rect corner1 and corner2
    self.detectArea = {
      {pos[1] + detectArea[1][1], pos[2] + detectArea[1][2]},
      {pos[1] + detectArea[2][1], pos[2] + detectArea[2][2]}
    }
  end
end

function update(dt) 
  if animator.animationState("doorState") == "closed" then
    local entityIds = world.entityQuery(self.detectArea[1], self.detectArea[2], {
        includedTypes = { "player", "npc" },
        boundMode = "CollisionArea",
        order = "nearest"
      })
    if #entityIds > 0 then
      
      if world.entityVelocity(entityIds[1])[1] > 0.1 then
        animator.setAnimationState("doorState", "swingRight")
        animator.playSound("swing")
      elseif world.entityVelocity(entityIds[1])[1] < -0.1 then
        animator.setAnimationState("doorState", "swingLeft")
        animator.playSound("swing")
      end
    end
  end
end

function doorOccupiesSpace(position)
  local relative = {position[1] - object.position()[1], position[2] - object.position()[2]}
  for _, space in ipairs(object.spaces()) do
    if math.floor(relative[1]) == space[1] and math.floor(relative[2]) == space[2] then
      return true
    end
  end
  return false
end
