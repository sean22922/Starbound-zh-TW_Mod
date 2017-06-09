require "/scripts/interp.lua"
require "/scripts/vec2.lua"
require "/scripts/poly.lua"
require "/scripts/util.lua"

Relocate = WeaponAbility:new()

function Relocate:init()
  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = 0 
  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end

  storage.storedMonsters = storage.storedMonsters or jarray()
  animator.setGlobalTag("absorbed", string.format("%s", #storage.storedMonsters))

  message.setHandler("confirmRelocate", function(_,_, monsterId, petInfo)
    if #storage.storedMonsters < self.maxStorage and (self.weapon.currentState == nil or self.weapon.currentState == self.scan) then
      petInfo.parameters = petInfo.parameters or {}
      petInfo.parameters.persistent = true
      petInfo.parameters.wasRelocated = true
      table.insert(storage.storedMonsters, petInfo)

      self:setState(self.absorb, monsterId, petInfo)
      return true
    else
      return false
    end
  end)
end

function Relocate:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(self.cooldownTimer - dt, 0.0)

  if self.fireMode == "alt"
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0 then

    if #storage.storedMonsters < self.maxStorage then
      self:setState(self.scan)
    else
      animator.playSound("error")
      self.cooldownTimer = self.cooldownTime
    end
  end

  local mag = world.magnitude(mcontroller.position(), activeItem.ownerAimPosition())
  if self.fireMode == "primary"
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and #storage.storedMonsters > 0
    and mag > vec2.mag(self.weapon.muzzleOffset) and mag < self.maxRange
    and not world.lineTileCollision(self:firePosition(), activeItem.ownerAimPosition()) then

    self:setState(self.fire)
  end
end

function Relocate:scan()
  animator.playSound("scan")
  animator.playSound("scanning", -1)

  local promises = {}
  while self.fireMode == "alt" do
    local monsters = world.entityQuery(activeItem.ownerAimPosition(), 2, { includedTypes = { "monster" }, order = "nearest" })
    monsters = util.filter(monsters, function(monsterId)
      local position = world.entityPosition(monsterId)
      if world.lineTileCollision(self:firePosition(), position) then
        return false
      end
      local mag = world.magnitude(mcontroller.position(), position)
      if mag > self.maxRange or mag < vec2.mag(self.weapon.muzzleOffset) then
        return false
      end
      if not contains({"enemy", "friendly", "passive"}, world.entityDamageTeam(monsterId).type) then
        return false
      end

      return true
    end)

    for _,monsterId in ipairs(monsters) do
      if not promises[monsterId] then
        promises[monsterId] = true
        local promise = world.sendEntityMessage(monsterId, "pet.attemptRelocate", activeItem.ownerEntityId())

        while not promise:finished() do
          coroutine.yield()
        end

        break
      end
    end
    coroutine.yield()
  end

  animator.stopAllSounds("scanning")
  animator.playSound("scanend")
end

function Relocate:absorb(entityId, monster)
  animator.stopAllSounds("scanning")
  self.weapon:setStance(self.stances.absorb)
  animator.playSound("start")
  animator.playSound("loop", -1)
  animator.setGlobalTag("absorbed", string.format("%s", #storage.storedMonsters))

  local monsterPosition = {0, 0}

  local timer = 0
  while timer < self.beamReturnTime do
    if world.entityExists(entityId) then
      monsterPosition = vec2.add(world.entityPosition(entityId), monster.attachPoint)
    end
    self.weapon.aimAngle, self.weapon.aimDirection = activeItem.aimAngleAndDirection(self.weapon.aimOffset, monsterPosition)
    local offset = self:beamPosition(monsterPosition)
    self:drawBeam(vec2.add(self:firePosition(), vec2.mul(offset, timer / self.beamReturnTime)), false)

    timer = timer + script.updateDt()
    coroutine.yield()
  end

  local stoppedBeam = false

  while world.entityExists(entityId) do
    self.weapon.aimAngle, self.weapon.aimDirection = activeItem.aimAngleAndDirection(self.weapon.aimOffset, monsterPosition)
    monsterPosition = vec2.add(world.entityPosition(entityId), monster.attachPoint)
    
    local offset = self:beamPosition(monsterPosition)
    self:drawBeam(vec2.add(self:firePosition(), offset), false)

    coroutine.yield()
  end

  animator.stopAllSounds("loop")
  animator.playSound("stop")

  timer = self.beamReturnTime
  while timer > 0 do
    local offset = self:beamPosition(monsterPosition)
    self:drawBeam(vec2.add(self:firePosition(), vec2.mul(offset, timer / self.beamReturnTime)), false)

    timer = timer - script.updateDt()

    coroutine.yield()
  end

  self.cooldownTimer = self.cooldownTime
end

function Relocate:fire()
  self.weapon:setStance(self.stances.absorb)
  animator.playSound("start")
  animator.playSound("loop", -1)

  local spawnPosition = activeItem.ownerAimPosition()

  local last = #storage.storedMonsters
  local monster = storage.storedMonsters[last]

  local timer = 0
  while timer < self.beamReturnTime do
    self.weapon.aimAngle, self.weapon.aimDirection = activeItem.aimAngleAndDirection(self.weapon.aimOffset, spawnPosition)

    local offset = self:beamPosition(spawnPosition)
    self:drawBeam(vec2.add(self:firePosition(), vec2.mul(offset, timer / self.beamReturnTime)), false)
    timer = timer + script.updateDt()

    coroutine.yield()
  end

  if not world.polyCollision(poly.translate(monster.collisionPoly, spawnPosition)) then
    world.spawnMonster(monster.monsterType, vec2.sub(spawnPosition, monster.attachPoint), monster.parameters)
    storage.storedMonsters[last] = nil
    animator.setGlobalTag("absorbed", string.format("%s", #storage.storedMonsters))

    util.wait(0.3, function()
      self.weapon.aimAngle, self.weapon.aimDirection = activeItem.aimAngleAndDirection(self.weapon.aimOffset, spawnPosition)

      local offset = self:beamPosition(spawnPosition)
      self:drawBeam(vec2.add(self:firePosition(), offset), false)
    end)
  else
    animator.playSound("error")
  end

  animator.stopAllSounds("loop")
  animator.playSound("stop")

  timer = self.beamReturnTime
  while timer > 0 do
    self.weapon.aimAngle, self.weapon.aimDirection = activeItem.aimAngleAndDirection(self.weapon.aimOffset, spawnPosition)

    local offset = self:beamPosition(spawnPosition)
    self:drawBeam(vec2.add(self:firePosition(), vec2.mul(offset, timer / self.beamReturnTime)), false)
    timer = timer - script.updateDt()

    coroutine.yield()
  end

  self.cooldownTimer = self.cooldownTime
end

function Relocate:drawBeam(endPos, didCollide)
  local newChain = copy(self.chain)
  newChain.startOffset = self.weapon.muzzleOffset
  newChain.endPosition = endPos

  if didCollide then
    newChain.endSegmentImage = nil
  end

  activeItem.setScriptedAnimationParameter("chains", {newChain})
end

function Relocate:beamPosition(aimPosition)
  local offset = vec2.mul(vec2.withAngle(self.weapon.aimAngle, math.max(0, world.magnitude(aimPosition, self:firePosition()))), {self.weapon.aimDirection, 1})
  if vec2.dot(offset, world.distance(aimPosition, self:firePosition())) < 0 then
    -- don't draw the beam backwards
    offset = {0,0}
  end
  return offset
end

function Relocate:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function Relocate:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function Relocate:uninit()
  self:reset()
end

function Relocate:reset()
  animator.stopAllSounds("loop")
  self.weapon:setDamage()
  activeItem.setScriptedAnimationParameter("chains", {})
end
