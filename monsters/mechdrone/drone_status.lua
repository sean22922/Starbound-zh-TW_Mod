require "/scripts/vec2.lua"

function init()
  self.damageFlashTime = 0
end

function applyDamageRequest(damageRequest)
  if world.getProperty("nonCombat") then
    return {}
  end

  local damage = 0
  if damageRequest.damageType == "Damage" or damageRequest.damageType == "IgnoresDef" then
    damage = damage + damageRequest.damage
  else
    return {}
  end

  local healthLost = math.min(damage, status.resource("health"))
  status.modifyResource("health", -healthLost)

  local hitType = damageRequest.hitType
  if not status.resourcePositive("health") then
    hitType = "kill"
  end

  return {{
    sourceEntityId = damageRequest.sourceEntityId,
    targetEntityId = entity.id(),
    position = mcontroller.position(),
    damageDealt = damage,
    healthLost = healthLost,
    hitType = hitType,
    kind = "Normal",
    damageSourceKind = damageRequest.damageSourceKind,
    targetMaterialKind = status.statusProperty("targetMaterialKind")
  }}
end

function update(dt)
  if self.damageFlashTime > 0 then
    status.setPrimaryDirectives(string.format("fade=%s", "ff0000=0.85"))
  else
    status.setPrimaryDirectives()
  end
  self.damageFlashTime = math.max(0, self.damageFlashTime - dt)
end
