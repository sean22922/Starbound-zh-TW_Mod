function init()
  self.detectEntityTypes = config.getParameter("detectEntityTypes")
  self.detectBoundMode = config.getParameter("detectBoundMode", "CollisionArea")
  self.detectLine = config.getParameter("detectLine")
  local pos = object.position()
  self.detectLine[1] = {self.detectLine[1][1] + pos[1], self.detectLine[1][2] + pos[2]}
  self.detectLine[2] = {self.detectLine[2][1] + pos[1], self.detectLine[2][2] + pos[2]}

  object.setAllOutputNodes(false)
end

function update(dt)
  if object.isInputNodeConnected(0) and not object.getInputNodeLevel(0) then
    object.setAllOutputNodes(false)
    animator.setAnimationState("sensorState", "off")
  else
    local entityIds = world.entityLineQuery(self.detectLine[1], self.detectLine[2], {
        withoutEntityId = entity.id(),
        includedTypes = self.detectEntityTypes,
        boundMode = self.detectBoundMode
      })
    if #entityIds > 0 then
      object.setAllOutputNodes(true)
      animator.setAnimationState("sensorState", "trigger")
    else
      object.setAllOutputNodes(false)
      animator.setAnimationState("sensorState", "on")
    end
  end
end
