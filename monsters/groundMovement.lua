groundMovement = {}

function groundMovement.create(obstacleHeightThreshold, obstacleLookaheadDistance, setAnimationState)
  local bounds = config.getParameter("metaBoundBox")
  local width = bounds[3] - bounds[1]
  local jumpDirection = nil

  local jump = function(direction)
    jumpDirection = direction
    mcontroller.controlJump()
    setAnimationState("jump")
  end

  local klass = {}
  function klass.move(position, direction, traverseObstacles, run)
    if not mcontroller.onGround() and jumpDirection ~= nil then
      mcontroller.controlHoldJump()
      mcontroller.controlMove(jumpDirection, run)

      return true
    end

    local positionedBounds = {
      bounds[1] + position[1],
      bounds[2] + position[2],
      bounds[3] + position[1],
      bounds[4] + position[2]
    }

    -- Jump over obstacles
    local jumpRegion = { positionedBounds[1], positionedBounds[2] + obstacleHeightThreshold, positionedBounds[3], positionedBounds[4] }
    if direction > 0 then
      jumpRegion[1] = jumpRegion[1] + width
      jumpRegion[3] = jumpRegion[3] + obstacleLookaheadDistance
    else
      jumpRegion[1] = jumpRegion[1] - obstacleLookaheadDistance
      jumpRegion[3] = jumpRegion[3] - width
    end

    if world.rectCollision(jumpRegion, {"Null", "Block", "Dynamic", "Slippery"}) then
      local jumpClearanceRegion = {
        positionedBounds[1] + direction * (positionedBounds[3] - positionedBounds[1]),
        positionedBounds[2] + obstacleHeightThreshold + 0.125,
        positionedBounds[3] + direction * (obstacleLookaheadDistance + positionedBounds[3] - positionedBounds[1]),
        positionedBounds[4] + obstacleHeightThreshold
      }
      if direction > 0 then
        jumpClearanceRegion[1] = jumpClearanceRegion[1] + width
        jumpClearanceRegion[3] = jumpClearanceRegion[3] + (obstacleLookaheadDistance + width)
      else
        jumpClearanceRegion[1] = jumpClearanceRegion[1] - (obstacleLookaheadDistance + width)
        jumpClearanceRegion[3] = jumpClearanceRegion[3] - width
      end
      if not world.rectCollision(jumpClearanceRegion, {"Null", "Block", "Dynamic", "Slippery"}) then
        if traverseObstacles then
          jump(direction)
        end

        return traverseObstacles
      end
    end

    -- Jump over gaps
    local gapRegion = { positionedBounds[1], positionedBounds[2] - obstacleLookaheadDistance, positionedBounds[3], positionedBounds[2] }
    if direction > 0 then
      gapRegion[1] = gapRegion[1] + width
      gapRegion[3] = gapRegion[3] + width / 2
    else
      gapRegion[1] = gapRegion[1] - width / 2
      gapRegion[3] = gapRegion[3] - width
    end

    if not world.rectCollision(gapRegion, {"Null", "Block", "Dynamic", "Platform"}) then
      if traverseObstacles then
        jump(direction)
      end

      return traverseObstacles
    end

    jumpDirection = nil

    if not traverseObstacles then
      local blockedRect = {
        positionedBounds[1] + direction, positionedBounds[2] + 1,
        positionedBounds[3] + direction, positionedBounds[4]
      }
      if world.rectCollision(blockedRect, {"Null", "Block", "Dynamic", "Slippery"}) then
        return false
      end
    end

    setAnimationState("run")
    mcontroller.controlMove(direction, run)

    return true
  end

  return klass
end
