flocking = {}

-- if entitiesToFind argument is given, it should be a table where the keys are
-- property names to check, and the values are 0. the value will be set to the
-- first entityId of a flock-mate that returns a truthy value for the property
function flocking.calculateMovement(flockGroupFunctionName, entitiesToFind)
  local movement = { 0, 0 }

  local selfPosition = mcontroller.position()
  local selfEntityId = entity.id()

  local flockRegion = config.getParameter("flockRegion")
  local flockRegionMin = { selfPosition[1] + flockRegion[1][1], selfPosition[2] + flockRegion[1][2] }
  local flockRegionMax = { selfPosition[1] + flockRegion[2][1], selfPosition[2] + flockRegion[2][2] }

  local flockSeparationDistance = config.getParameter("flockSeparationDistance")
  local flockAlignmentDistance = config.getParameter("flockAlignmentDistance")

  -- Gather flock measurements
  local hasLeader = false
  local flockPositions, flockSeparations, flockHeadings = {}, {}, {}

  for i, entityId in ipairs(world.entityQuery(flockRegionMin, flockRegionMax, {includedTypes={"monster"}})) do
    if entityId ~= selfEntityId then
      local flockPromise = world.sendEntityMessage(entityId, flockGroupFunctionName)
      if flockPromise:finished() and flockPromise:result() then
        local flockInfo = flockPromise:result()
        if flockInfo.isLeader then
          hasLeader = true
        end

        local position = world.entityPosition(entityId)
        local separation = world.distance(selfPosition, position)
        local distance = world.magnitude(separation)

        -- Minimum cohesion distance is controlled by the size of the flock region
        table.insert(flockPositions, position)

        if distance < flockSeparationDistance then
          table.insert(flockSeparations, { separation[1] / distance, separation[2] / distance, distance })
        end

        if distance < flockAlignmentDistance then
          local heading = flockInfo.movement
          if heading ~= nil then
            if flockInfo.isLeader then
              local flockLeaderInfluence = config.getParameter("flockLeaderInfluence")
              heading[1] = heading[1] * flockLeaderInfluence
              heading[2] = heading[2] * flockLeaderInfluence
            end
            table.insert(flockHeadings, heading)
          end
        end

        if entitiesToFind ~= nil then
          for flagName, flagValue in pairs(entitiesToFind) do
            if flagValue == 0 and flockInfo[flagName] then
              entitiesToFind[flagName] = entityId
            end
          end
        end
      end
    end
  end

  if hasLeader then
    self.isFlockLeader = false
  else
    self.isFlockLeader = true
  end

  -- Apply separation
  if #flockSeparations > 0 then
    local totalSeparation = {0,0}
    for i, separation in ipairs(flockSeparations) do
      local x, y, magnitude = table.unpack(separation)
      -- x and y will be nan if magnitude is zero, so just ignore it and hope
      -- that other factors move the flock mates so they aren't in the same spot
      if magnitude > 0 then
        local relativeDistance = (flockSeparationDistance - magnitude) / flockSeparationDistance
        local relativeDistanceSq = relativeDistance * relativeDistance
        totalSeparation[1] = totalSeparation[1] + x * relativeDistanceSq
        totalSeparation[2] = totalSeparation[2] + y * relativeDistanceSq
      end
    end

    local flockSeparationFactor = config.getParameter("flockSeparationFactor")
    movement[1] = movement[1] + totalSeparation[1] * flockSeparationFactor
    movement[2] = movement[2] + totalSeparation[2] * flockSeparationFactor
  end

  -- Apply alignment
  if #flockHeadings > 0 then
    local totalHeading = {0,0}
    for i, heading in ipairs(flockHeadings) do
      totalHeading[1] = totalHeading[1] + heading[1]
      totalHeading[2] = totalHeading[2] + heading[2]
    end

    local averageHeading = {
      totalHeading[1] / #flockHeadings,
      totalHeading[2] / #flockHeadings
    }

    local flockAlignmentFactor = config.getParameter("flockAlignmentFactor")
    movement[1] = movement[1] + averageHeading[1] * flockAlignmentFactor
    movement[2] = movement[2] + averageHeading[2] * flockAlignmentFactor
  end

  -- Apply cohesion
  if #flockPositions > 0 then
    local toAveragePosition = {0,0}
    for i, position in ipairs(flockPositions) do
      local toPosition = world.distance(position, selfPosition)
      toAveragePosition[1] = toAveragePosition[1] + toPosition[1]
      toAveragePosition[2] = toAveragePosition[2] + toPosition[2]
    end
    toAveragePosition[1] = toAveragePosition[1] / #flockPositions
    toAveragePosition[2] = toAveragePosition[2] / #flockPositions

    local flockCohesionFactor = config.getParameter("flockCohesionFactor")
    movement[1] = movement[1] + toAveragePosition[1] * flockCohesionFactor
    movement[2] = movement[2] + toAveragePosition[2] * flockCohesionFactor
  end

  return movement
end
