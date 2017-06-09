require "/scripts/util.lua"

function update()
  localAnimator.clearDrawables()

  local markerImage = animationConfig.animationParameter("markerImage")
  if markerImage then
    local entities = animationConfig.animationParameter("entities") or {}
    entities = util.filter(entities, world.entityExists)
    for _,entityId in pairs(entities) do
      localAnimator.addDrawable({image = markerImage, position = world.entityPosition(entityId)}, "overlay")
    end
  end
end
