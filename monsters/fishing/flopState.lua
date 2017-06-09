require "/scripts/util.lua"

flopState = {}

function flopState.enter()
  if not self.inLiquid then
    return { jumpTimer = 0, jumpDirection = util.randomDirection() }
  end
end

function flopState.enteringState(stateData)
  animator.setAnimationState("movement", "panicSlow")
end

function flopState.update(dt, stateData)
  if self.inLiquid then return true end

  mcontroller.controlParameters({ bounceFactor = 0.6 })

  stateData.jumpTimer = stateData.jumpTimer - dt
  if mcontroller.onGround() then
    if stateData.jumpTimer <= 0 then
      stateData.jumpDirection = util.randomDirection()
      mcontroller.controlMove(stateData.jumpDirection)
      mcontroller.controlJump()
    else
      mcontroller.controlDown()
    end
  end

  if stateData.jumpTimer <= 0 then
    stateData.jumpTimer = util.randomInRange(config.getParameter("flopJumpInterval"))
  end

  return false
end

function flopState.leavingState(stateData)

end
