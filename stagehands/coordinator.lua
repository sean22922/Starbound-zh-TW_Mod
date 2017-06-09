require("/scripts/util.lua")

function init()
  local min = config.getParameter("minMembers")
  local max = config.getParameter("maxMembers")
  self.goalType = config.getParameter("goalType")
  self.goal = config.getParameter("goal")
  self.groupId = config.getParameter("groupId")

  self.groupResources = ResourceSet:new()
  self.memberResources = {}

  self.group = Group:new(self.groupId, min, max)
  self.group.onJoin = function(entityId)
    self.memberResources[entityId] = ResourceSet:new()
  end
  self.group.onLeave = function(entityId)
    self.memberResources[entityId] = nil
    for _,task in pairs(self.tasks) do
      task:leave(entityId)
    end
  end

  self.success = false

  if config.getParameter("behavior") then
    self.behavior = behavior.behavior(config.getParameter("behavior"), config.getParameter("behaviorConfig", {}), _ENV)
  end

  self.tasks = {}
end

function uninit()
end

function update(dt)
  if self.behavior then
    self.behavior:run(dt)
  end

  if #self.group.members == 0 and #self.group.members == 0 then
    die()
  end

  if self.goalType == "entity" then
    if self.goal and world.entityExists(self.goal) then
      stagehand.setPosition(world.entityPosition(self.goal))
    else
      die()
    end
  end

  self.group:update()
  for _,task in pairs(self.tasks) do
    task:update()
  end

  self.groupResources:update()
  for _,memberSet in pairs(self.memberResources) do
    memberSet:update()
  end
end

function die()
  self.dead = true
  stagehand.die()
end

function onRequestJoin(entityId, goalType, goal)
  if self.dead then return false end

  if self.success then
    if self.group:hasMember(entityId) then
      return "success"
    end
  else
    return self.group:join(entityId)
  end
end

function onLeaveGroup(entityId)
  return self.group:leave(entityId)
end

function onRequestTask(entityId, task)
  if not self.tasks[task.taskId] then
    self.tasks[task.taskId] = Group:new(task.taskId, task.minMembers, task.maxMembers)
  end
  return self.tasks[task.taskId]:join(entityId) == true
end

function onLeaveTask(entityId, taskId)
  if self.tasks[taskId] then
    return self.tasks[taskId]:leave(entityId)
  end
end

function onGetResource(entityId, resource)
  local memberResource = self.memberResources[entityId]:get(resource)
  if memberResource ~= nil then
    return memberResource
  else
    return self.groupResources:get(resource)
  end
end

function setSuccess(entityId)
  self.success = true
end

function compareGoals(goalType, goal)
  if goalType ~= self.goalType then return false end
  if goalType == "entity" then
    return goal == self.goal
  elseif goalType == "position" then
    return goal[1] == self.goal[1] and goal[2] == self.goal[2]
  elseif goalType == "list" then
    if #goal == #self.goal then
      for _,value in pairs(goal) do
        if not contains(self.goal, value) then
          return false
        end
      end
      return true
    end
  end
  return false
end

-- GROUPS
local extend = function(base)
  return {
    __index = function(t,k)
      local raw = rawget(t,k)
      if raw == nil then
        return base[k]
      else
        return raw
      end
    end
  }
end

Group = {}

function Group:new(id, min, max)
  newGroup = {
    id = id,
    min = min,
    max = max,
    members = {}
  }
  setmetatable(newGroup, extend(self))
  return newGroup
end

function Group:update(dt)
  self.members = util.filter(self.members, function (memberId)
      return world.entityExists(memberId)
    end)
end

function Group:hasMember(entityId)
  for _,memberid in pairs(self.members) do
    if memberid == entityId then
      return true
    end
  end
end

function Group:join(entityId)
  if self:hasMember(entityId) then
    if #self.members >= self.min then
      return true
    else
      return "min"
    end
  end

  if #self.members >= self.max then
    return false
  else
    table.insert(self.members, entityId)
    if self.onJoin then self.onJoin(entityId) end
    if #self.members < self.min then
      return "min"
    end
    return true
  end
end

function Group:leave(memberId)
  if self.leaveCallback then
    self.leaveCallback(memberId)
  end
  for k,v in pairs(self.members) do
    if memberId == v then
      table.remove(self.members, k)
    if self.onLeave then self.onLeave(memberId) end
    end
  end
end

function inList(list, value)
  for k,v in pairs(list) do
    if v == value then return true end
  end
  return false
end

-- RESOURCES

ResourceSet = {}

function ResourceSet:new()
  local newSet = {
    resources = {},
    newResources = {}
  }
  setmetatable(newSet, extend(self))
  return newSet
end

function ResourceSet:set(k,v)
  self.newResources[k] = v
end

function ResourceSet:get(k)
  return self.newResources[k] or self.resources[k]
end

function ResourceSet:update()
  self.resources = self.newResources
  self.newResources = {}
end
