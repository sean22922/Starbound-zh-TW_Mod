require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  self.waitTime = config.getParameter("waitTime", 0.5)
  self.moveTime = config.getParameter("moveTime", 0.2)
  self.state = "wait"
  self.stateTimer = self.waitTime

  self.aimPosition = mcontroller.position()

  message.setHandler("updateProjectile", function(_, _, aimPosition)
      if not self.targetOffset then
        self.targetOffset = world.distance(mcontroller.position(), aimPosition)
      end
      self.aimPosition = aimPosition
      return entity.id()
    end)

  message.setHandler("kill", projectile.die)
end

function update(dt)
  self.stateTimer = math.max(0, self.stateTimer - dt)

  if self.stateTimer == 0 and self.targetOffset then
    if self.state == "wait" then
      self.state = "move"
      self.stateTimer = self.moveTime

      self.targetOffset = vec2.rotate(self.targetOffset, math.pi)

      local targetPosition = vec2.add(self.aimPosition, self.targetOffset)
      mcontroller.setVelocity(vec2.div(world.distance(targetPosition, mcontroller.position()), self.moveTime))
    elseif self.state == "move" then
      self.state = "wait"
      self.stateTimer = self.waitTime
      mcontroller.setVelocity({0, 0})
    end
  end
end
