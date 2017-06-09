require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"

-- Pickaxe primary ability
PickSlash = WeaponAbility:new()

function PickSlash:init()
  self.weapon:setStance(self.stances.idle)

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
    self:setAnimationStates(self.onLeaveAnimationStates)
  end
end

function PickSlash:setAnimationStates(states)
  for stateType, state in pairs(states or {}) do
    animator.setAnimationState(stateType, state)
  end
end

-- Ticks on every update regardless if this is the active ability
function PickSlash:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  if not self.weapon.currentAbility and self:shouldFire() then
    self:setState(self.windup)
  end
end

function PickSlash:bladeReady()
  for stateType, state in pairs(self.requisiteAnimationStates or {}) do
    if animator.animationState(stateType) ~= state then
      return false
    end
  end
  return true
end

function PickSlash:canFire()
  return not status.resourceLocked("energy") and status.resourcePositive("energy")
end

function PickSlash:shouldFire()
  return self:canFire() and self.fireMode == self.activatingFireMode
end

-- State: windup
function PickSlash:windup()
  self.weapon:setStance(self.stances.windup)
  self.weapon:updateAim()

  if not self:bladeReady() then
    self:setAnimationStates(self.windupAnimationStates)
  end

  while not self:bladeReady() do
    coroutine.yield()
  end

  if self:shouldFire() then
    self:setState(self.fire)
  end
end

-- State: fire
function PickSlash:fire()
  local entityPosition = world.entityPosition(activeItem.ownerEntityId())
  self.hitPosition = activeItem.ownerAimPosition()
  local distance = vec2.mag(world.distance(entityPosition, self.hitPosition))
  if distance > self.toolRange then
    coroutine.yield()
    self:setState(self.windup)
    return
  end

  local radius = self.shiftHeld and self.altBlockRadius or self.blockRadius
  local brushArea = self:tileAreaBrush(radius, self.hitPosition)

  if not world.damageTiles(brushArea, self.layer, entityPosition, self.tileDamageType, self.tileDamage, self.harvestLevel) then
    coroutine.yield()
    self:setState(self.windup)
    return
  end
  status.overConsumeResource("energy", self.energyUsage)

  animator.setSoundPool("blockSound", {self:getBlockSound(brushArea)})

  self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()

  coroutine.yield()

  animator.playSound("blockSound")
  animator.playSound("fire")

  util.wait(self.stances.fire.duration)

  if self:shouldFire() then
    self:setState(self.fire)
  end
end

function PickSlash:getBlockSound(brushArea)
  local defaultFootstepSound = root.assetJson("/client.config:defaultFootstepSound")

  for _,pos in pairs(brushArea) do
    if world.isTileProtected(pos) then
      return root.assetJson("/client.config:defaultDingSound")
    end
  end

  for _,pos in pairs(brushArea) do
    local material = world.material(pos, self.layer)
    local mod = world.mod(pos, self.layer)
    local blockSound = type(material) == "string" and root.materialMiningSound(material, mod)
    if blockSound then return blockSound end
  end

  for _,pos in pairs(brushArea) do
    local material = world.material(pos, self.layer)
    local mod = world.mod(pos, self.layer)
    local blockSound = type(material) == "string" and root.materialFootstepSound(material, mod)
    if blockSound and blockSound ~= defaultFootstepSound then
      return blockSound
    end
  end

  return nil
end

function PickSlash:tileAreaBrush(radius, centerPosition)
  local result = jarray()
  local offset = {-radius/2, -radius/2}
  local intOffset = util.map(vec2.add(offset, centerPosition), util.round)

  for x = 0, radius-1 do
    for y = 0, radius-1 do
      local intPos = util.map({x, y}, util.round)
      table.insert(result, vec2.add(intPos, intOffset))
    end
  end
  return result
end

function PickSlash:uninit()
end
