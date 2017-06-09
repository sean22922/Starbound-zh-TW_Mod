-- Lua helpers
function extend(base)
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

-- Table/list helpers
function compare(t1,t2)
  if t1 == t2 then return true end
  if type(t1) ~= type(t2) then return false end
  if type(t1) ~= "table" then return false end
  for k,v in pairs(t1) do
    if not compare(v, t2[k]) then return false end
  end
  for k,v in pairs(t2) do
    if not compare(v, t1[k]) then return false end
  end
  return true  
end

function copy(v)
  if type(v) ~= "table" then
    return v
  else
    local c = {}
    for k,v in pairs(v) do
      c[k] = copy(v)
    end
    return c
  end
end

function filter(t, f)
  local filtered = {}
  for k,v in pairs(t) do
    if f(v) == true then
      table.insert(filtered, v)
    end
  end
  return filtered
end

function contains(t, v1)
  for _,v2 in ipairs(t) do
    if compare(v1, v2) then
      return true
    end
  end
  return false
end

function containsAny(t1, t2)
  for _,v1 in ipairs(t1) do
    if contains(t2, v1) then
      return true
    end
  end
  return false
end

function containsAll(t1, t2)
  for _,v in ipairs(t2) do
    if not contains(t1, v) then
      return false
    end
  end
  return true
end

function shuffle(t)
  local shuffled = {}
  for k,v in ipairs(t) do
    shuffled[k] = {math.random(), v}
  end
  table.sort(shuffled, function(a,b) return a[1] < b[1] end)
  for k,v in ipairs(t) do
    shuffled[k] = t[2]
  end
  return shuffled
end

-- Geometry helpers
function pointInRect(rect, point)
  if point[1] >= rect[1] and point[1] <= rect[3]
     and point[2] >= rect[2] and point[2] <= rect[4] then
    return true
  else
    return false
  end
end

function translateRect(rect, offset)
  return {
    rect[1] + offset[1], rect[2] + offset[2],
    rect[3] + offset[1], rect[4] + offset[2]
  }
end

--Events
Event = {}
function Event:new()
  local newEvent = {
    callbacks = {}
  }
  setmetatable(newEvent, extend(self))
  return newEvent
end
function Event:register(func)
  table.insert(self.callbacks, func)
end
function Event:trigger(...)
  for _,callback in pairs(self.callbacks) do
    callback(...)
  end
end
