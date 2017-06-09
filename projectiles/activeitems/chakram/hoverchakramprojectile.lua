require "/scripts/vec2.lua"

function init()
  self.returning = config.getParameter("returning", false)
  self.returnOnHit = config.getParameter("returnOnHit", false)
  self.pickupDistance = config.getParameter("pickupDistance")
  self.timeToLive = config.getParameter("timeToLive")
  self.speed = config.getParameter("speed")
  self.ownerId = projectile.sourceEntity()

  self.hoverMaxDistance = config.getParameter("hoverMaxDistance")
  self.hoverTime = config.getParameter("hoverTime")

  self.initialPosition = mcontroller.position()
  local aimPosition = config.getParameter("ownerAimPosition")
  self.hoverDistance = math.min(self.hoverMaxDistance, world.magnitude(self.initialPosition, aimPosition))
  self.hoverPosition = vec2.add(vec2.mul(vec2.norm(mcontroller.velocity()), self.hoverDistance), self.initialPosition)
end

function update(dt)
  if self.ownerId and world.entityExists(self.ownerId) then
    if not self.returning then
      if self.hoverTimer then
        self.hoverTimer = math.max(0, self.hoverTimer - dt)
      end

      if mcontroller.isColliding() or self.hoverTimer == 0 then
        self.returning = true
      elseif self.hoverTimer then
        mcontroller.approachVelocity({0,0}, 1000)
      else
        local distanceToHover = self.hoverDistance - world.magnitude(mcontroller.position(), self.initialPosition)
        if distanceToHover < 0.5 then
          self.hoverTimer = self.hoverTime
          mcontroller.setVelocity({0,0})
          mcontroller.setPosition(self.hoverPosition)
        elseif distanceToHover < 5 then
          mcontroller.approachVelocity({0,0}, 300)
        end
      end
    else
      mcontroller.applyParameters({collisionEnabled=false})
      local toTarget = world.distance(world.entityPosition(self.ownerId), mcontroller.position())
      if vec2.mag(toTarget) < self.pickupDistance then
        projectile.die()
      else
        mcontroller.setVelocity(vec2.mul(vec2.norm(toTarget), self.speed))
      end
    end
  else
    projectile.die()
  end
end

function hit(entityId)
  if self.returnOnHit then self.returning = true end
end

function projectileIds()
  return {entity.id()}
end
