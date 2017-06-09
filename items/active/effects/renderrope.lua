require "/scripts/vec2.lua"

function update()
  localAnimator.clearDrawables()

  local ropeParticle = animationConfig.animationParameter("ropeParticle")
  local ropeParticleDensity = animationConfig.animationParameter("ropeParticleDensity")

  local lastPoint = activeItemAnimation.handPosition(animationConfig.animationParameter("ropeOffset"))
  for i = 2, 1000 do
    local nextPoint = animationConfig.animationParameter("p"..i)
    if nextPoint == nil then
      break
    end

    local position = activeItemAnimation.ownerPosition()
    local relativeNextPoint = world.distance(nextPoint, position)
    localAnimator.addDrawable({
        position = position,
        line = {lastPoint, relativeNextPoint},
        width = config.getParameter("ropeWidth"),
        color = animationConfig.animationParameter("ropeColor", config.getParameter("ropeColor")),
        fullbright = config.getParameter("ropeFullbright")
      }, "player-1")

    if ropeParticle and ropeParticleDensity and ropeParticleDensity > 0 then
      local segment = vec2.sub(relativeNextPoint, lastPoint)
      local particleCount = math.ceil(ropeParticleDensity * vec2.mag(segment))
      if particleCount > 0 then
        for i = 1, particleCount do
          local ppos = vec2.add(vec2.add(position, lastPoint), vec2.mul(segment, math.random()))
          localAnimator.spawnParticle(ropeParticle, ppos)
        end
      end
    end

    lastPoint = relativeNextPoint
  end
end
