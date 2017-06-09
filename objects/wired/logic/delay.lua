function init()
  self.queueSize = math.floor(config.getParameter("delay", 1.0) / script.updateDt() + 0.5)

  self.queue = {}
  for i = 1, self.queueSize do
    self.queue[i] = false
  end
  self.index = 1

  output(false)
end

function update(dt)
  local delayed = self.queue[self.index]
  if delayed ~= self.state then
    output(delayed)
  end
  self.queue[self.index] = object.getInputNodeLevel(0)

  self.index = self.index % self.queueSize + 1
end

function output(state)
  self.state = state
  object.setOutputNodeLevel(0, state)
  if state then
    animator.setAnimationState("switchState", "on")
  else
    animator.setAnimationState("switchState", "off")
  end
end
