require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/fishing/fishingspawner.lua"

function init()
  self.ownerId = projectile.sourceEntity()
  self.rodPosition = world.entityPosition(self.ownerId)
  self.lineLength = 50
  self.controls = {}
  self.hitLiquid = false
  self.hitGround = false
  self.bailFlip = false

  self.lineOffset = config.getParameter("lineOffset", {-0.75, 0})

  self.reelParameters = config.getParameter("reelParameters")
  self.lureParameters = config.getParameter("lureParameters")

  self.spawnTimeRange = config.getParameter("spawnTimeRange", {2, 6})

  self.scareFishRange = config.getParameter("scareFishRange", 9)
  self.scareFishTime = config.getParameter("scareFishTime", 1)
  self.scareFishTimer = 0

  message.setHandler("fishOn", function(_, _, fishId)
      world.sendEntityMessage(self.ownerId, "fishOn", fishId)
      return self.ownerId
    end)

  message.setHandler("updateLure", function(_, _, rodPosition, lineLength, controls)
      self.rodPosition = rodPosition
      self.lineLength = lineLength
      self.controls = controls
      if projectile.timeToLive() > 0 then
        projectile.setTimeToLive(2)
      end
    end)

  self.fishingSpawner = FishingSpawner()
end

function update(dt)
  if self.ownerId and world.entityExists(self.ownerId) then
    local onGround = mcontroller.onGround()
    if not self.hitGround and onGround then
      self.hitGround = true
    end

    -- sb.logInfo("controls are %s", self.controls)
    local inLiquid = world.liquidAt(mcontroller.position())
    if inLiquid then
      if not self.hitLiquid then
        self.spawnTimer = util.randomInRange(self.spawnTimeRange) * 2
      end
      self.hitLiquid = true


      self.spawnTimer = self.spawnTimer - dt
      if self.spawnTimer <= 0 then
        local spawnType, spawnPosition = self.fishingSpawner.getSpawn(mcontroller.position())
        if spawnType then
          local spawnParameters = {
            lureId = entity.id(),
            ownerId = self.ownerId,
            reelParameters = self.reelParameters,
            rodPosition = self.rodPosition,
            level = math.max(1, world.threatLevel())
          }

          world.spawnMonster(spawnType, spawnPosition, spawnParameters)
        end
        self.spawnTimer = util.randomInRange(self.spawnTimeRange)
      end

      self.scareFishTimer = self.scareFishTimer - dt
      if self.scareFishTimer <= 0 then
        local eId = entity.id()
        for i, targetId in ipairs(world.monsterQuery(entity.position(), self.scareFishRange)) do
          world.sendEntityMessage(targetId, "fleeFromLure", eId)
        end
        self.scareFishTimer = self.scareFishTime
      end
    else
      self.fishingSpawner.reset()
    end

    if self.controls.reel then
      self.bailFlip = true
    end

    local toRod = world.distance(self.rodPosition, mcontroller.position())
    if self.controls.reel then
      mcontroller.approachVelocityAlongAngle(vec2.angle(toRod), self.reelParameters.reelSpeed, 1000)
    elseif (self.bailFlip and not self.controls.down) or vec2.mag(toRod) >= self.lineLength then
      mcontroller.approachVelocityAlongAngle(vec2.angle(toRod), 0, 1000)
    end

    if inLiquid then
      if self.controls.left then
        mcontroller.approachVelocity({-self.lureParameters.controlSpeed, 0}, self.lureParameters.controlForce)
      elseif self.controls.right then
        mcontroller.approachVelocity({self.lureParameters.controlSpeed, 0}, self.lureParameters.controlForce)
      end
    end

    local vel = mcontroller.velocity()
    if not inLiquid then
      mcontroller.setRotation(math.pi + vec2.angle(toRod))
    else
      local angle = math.pi * 1.5
      angle = angle + math.max(-0.2, math.min(0.2, mcontroller.velocity()[1] * -0.07))
      mcontroller.setRotation(angle)
    end
  else
    projectile.die()
  end
end

function kill()
  projectile.die()
end

function linePosition()
  return vec2.add(mcontroller.position(), vec2.rotate(self.lineOffset, mcontroller.rotation()))
end
