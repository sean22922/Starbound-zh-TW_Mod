require "/scripts/util.lua"

local operators = {}

function check(achievement)
  for _, stat in ipairs(config.getParameter("stats")) do
    if not checkStat(stat) then
      return false
    end
  end
  return true
end

function checkStat(stat)
  local statValue = statistics.stat(stat.name)
  local op = operators[stat.op]
  assert(op ~= nil)
  return op(stat, statValue)
end

function operators.atLeast(args, currentValue)
  args = applyDefaults(args, {
      default = 0,
      value = 1
    })
  return (currentValue or args.default) >= args.value
end

function operators.atMost(args, currentValue)
  args = applyDefaults(args, {
      default = 0,
      value = 1
    })
  return (currentValue or args.default) <= args.value
end

function operators.sizeAtLeast(args, currentValue)
  args = applyDefaults(args, {
      default = {},
      value = 1
    })
  return util.tableSize(currentValue or args.default) >= args.value
end
