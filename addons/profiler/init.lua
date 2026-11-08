-- Where the time goes: measure() and wrap() time functions with os.clock (CPU time of this computer),
-- proxy() counts and times every call on a component (each one costs the server), report() sums it up
local M = {}

local entries = {}

function M.setup(settings)
  M.settings = settings
  entries = {}
end

local function record(name, seconds)
  local entry = entries[name]

  if entry == nil then
    entry = {name = name, calls = 0, total = 0, max = 0}
    entries[name] = entry
  end

  entry.calls = entry.calls + 1
  entry.total = entry.total + seconds
  entry.max = math.max(entry.max, seconds)
end

---Run fn and time it under a name; returns what fn returns (errors pass through, still timed)
function M.measure(name, fn, ...)
  local started = os.clock()
  local result = table.pack(pcall(fn, ...))
  record(name, os.clock() - started)

  if not result[1] then
    error(result[2], 0)
  end

  return table.unpack(result, 2, result.n)
end

---A function that times every call of fn under a name
function M.wrap(name, fn)
  return function (...)
    return M.measure(name, fn, ...)
  end
end

---A stand-in for a component proxy that counts and times every method call as "<name>.<method>"
function M.proxy(proxy, name)
  name = name or proxy.type or "component"

  return setmetatable({}, {__index = function (cache, key)
    local value = proxy[key]

    if type(value) == "function" or (type(value) == "table" and getmetatable(value) and getmetatable(value).__call) then
      local wrapped = M.wrap(name.."."..key, value)
      rawset(cache, key, wrapped)
      return wrapped
    end

    return value
  end})
end

---Totals, most time first: {{name, calls, total, avg, max}} (seconds)
function M.report(sortBy)
  local list = {}

  for _, entry in pairs(entries) do
    list[#list + 1] = {name = entry.name, calls = entry.calls, total = entry.total, avg = entry.total / entry.calls, max = entry.max}
  end

  sortBy = sortBy or "total"
  table.sort(list, function (a, b) return a[sortBy] > b[sortBy] end)
  return list
end

---The report as text lines for the screen or a file
function M.lines(n, sortBy)
  local lines = {string.format("%-32s %8s %10s %10s %10s", "NAME", "CALLS", "TOTAL ms", "AVG ms", "MAX ms")}

  for i, row in ipairs(M.report(sortBy)) do
    if n ~= nil and i > n then
      break
    end

    lines[#lines + 1] = string.format("%-32s %8d %10.1f %10.2f %10.2f", row.name:sub(1, 32), row.calls,
      row.total * 1000, row.avg * 1000, row.max * 1000)
  end

  return lines
end

function M.reset()
  entries = {}
end

return M
