require "/scripts/util.lua"

disappearState = {}

function disappearState.enter()
  if storage.stateStage == "disappear" or (storage.stateStage == "despawn" and self.inLiquid) then
    local escapeVector = vec2.mul(self.toLure, -1)
    if escapeVector[2] > 0 then escapeVector[2] = 0 end
    return {
      escapeVector = escapeVector
    }
  end
end

function disappearState.enteringState(stateData)
  animator.setAnimationState("movement", "swimFast")
end

function disappearState.update(dt, stateData)
  if not self.inLiquid then return true end

  self.targetOpacity = 0
  self.targetColorFade = 0
  if self.currentOpacity == 0 then
    monster.setDeathSound()
    monster.setDeathParticleBurst()
    status.setResource("health", 0)
  end

  if blocked(self.blockedSensors) or blocked(self.surfaceSensors) then
    stateData.escapeVector = vec2.rotate(stateData.escapeVector, util.randomInRange(math.pi - 0.5, math.pi + 0.5))
  end

  move(stateData.escapeVector, self.hookedSpeed)

  return false
end

function disappearState.leavingState(stateData)

end
