require "/scripts/vec2.lua"
require "/scripts/rect.lua"
require "/scripts/util.lua"
require "/objects/playerstation/stationgrid.lua"

function init()
  object.setInteractive(true)

  local partConfig = root.assetJson("/dungeons/space/playerstation/parts.config")
  self.expandDirection = config.getParameter("expandDirection")
  self.expandPosition = vec2.add(entity.position(), vec2.mul(self.expandDirection, partConfig.partBorder))
  message.setHandler("getGrid", function()
    local grid = getGrid()
    return {
      anchor = {direction = self.expandDirection, position = worldToTile(grid, self.expandPosition)},
      grid = grid
    }
  end)

  message.setHandler("lockPart", function(_,_, partName, tilePos)
    local console = world.loadUniqueEntity("playerstationconsole")
    if checkClear(partConfig.parts[partName]) then
      return {world.sendEntityMessage(console, "lockPartPlacement", entity.id(), partConfig.parts[partName], tilePos):result(), nil}
    else
      return {false, "blocked"}
    end
  end)

  message.setHandler("placePart", function(_,_, partName, tilePos)
    local grid = getGrid()
    world.spawnProjectile("stationpartsound", vec2.add(self.expandPosition, vec2.mul(grid.tileSize, vec2.mul(self.expandDirection, 0.5))))
    local console = world.loadUniqueEntity("playerstationconsole")
    return world.sendEntityMessage(console, "confirmPartPlacement", entity.id(), partConfig.parts[partName], tilePos):result()
  end)

  if storage.hidden then
    hide()
  else
    show()
  end
end

function update()
  if contains({0, 65532, 65531}, world.dungeonId(self.expandPosition)) then
    object.smash()
  end

  local hidden = checkHidden()
  if not hidden then
    local grid = getGrid()
    if not tileAvailable(grid, worldToTile(grid, self.expandPosition)) then
      hide()
    else
      show()
    end
  end
end

function checkClear(part)
  local grid = getGrid()
  local offset = anchoredPartOffset(part, self.expandDirection)
  if not offset then return false end
  local firstTile = vec2.add(worldToTile(grid, self.expandPosition), offset)
  for _,tile in pairs(partTiles(part, firstTile)) do
    local min = vec2.sub(tileWorldPos(grid, tile), vec2.div(grid.tileBorder, 2.0))
    local max = vec2.add(min, vec2.add(grid.tileSize, grid.tileBorder))

    local entities = world.entityQuery(min, max, {includedTypes = {"npc", "player", "monster"}})
    if #entities > 0 then
      return false
    end 
  end
  return true
end

function checkHidden()
  local console = world.loadUniqueEntity("playerstationconsole")
  if console then
    local hidden = world.sendEntityMessage(console, "hideExpansionSlots"):result()
    if hidden then
      hide()
      return true
    else
      show()
      return false
    end
  end
  return false
end

function getGrid()
  local console = world.loadUniqueEntity("playerstationconsole")
  if console then
    return world.sendEntityMessage(console, "grid"):result()
  end
end

function hide()
  storage.hidden = true
  object.setMaterialSpaces(config.getParameter("hiddenMaterialSpaces"))
  object.setInteractive(false)
  animator.setAnimationState("visibility", "invisible")
end

function show()
  storage.hidden = false
  object.setMaterialSpaces(config.getParameter("shownMaterialSpaces"))
  object.setInteractive(true)
  animator.setAnimationState("visibility", "visible")
end

function onInteraction(args)
  -- don't allow interaction from the expand direction
  if vec2.dot(args.source, self.expandDirection) < 0 then
    return {config.getParameter("interactAction"), config.getParameter("interactData")}
  else
    animator.playSound("interactError")
  end
end
