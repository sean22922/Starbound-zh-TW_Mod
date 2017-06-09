function createTimers()
  local self = {}
  local timers = {}

  self.start = function(delay, func)
    if delay <= 0 then
      func()
      return
    end

    table.insert(timers, { delay = delay, func = func })
  end

  self.tick = function(dt)
    for i, timer in ipairs(timers) do
      timer.delay = timer.delay - dt
      if timer.delay <= 0 then
        local newDelay = timer.func()
        if newDelay ~= nil then
          timer.delay = newDelay
        end
      end
    end

    for i = #timers, 1, -1 do
      if timers[i].delay <= 0 then
        table.remove(timers, i)
      end
    end
  end

  return self
end
