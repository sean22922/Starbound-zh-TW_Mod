function init()
  setupMaterialSpaces()

  object.setMaterialSpaces()
  animator.setAnimationState("rubbleState", "hidden")
end

function setDestroyed()
  object.setMaterialSpaces(self.closedMaterialSpaces)
  animator.setAnimationState("rubbleState", "shown")
end

function setupMaterialSpaces()
  self.closedMaterialSpaces = {}
  for i, space in ipairs(object.spaces()) do
    table.insert(self.closedMaterialSpaces, {space, "metamaterial:boundary"})
  end
end
