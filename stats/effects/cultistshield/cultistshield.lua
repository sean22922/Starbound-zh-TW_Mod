require "/scripts/status.lua"

function init()
  self.listener = damageListener("damageTaken", function()
    animator.setAnimationState("shield", "hit")
  end)

  effect.addStatModifierGroup({
    {stat = "protection", amount = 100.0},
  })
end

function update(dt)
  self.listener:update()
end
