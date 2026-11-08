-- Tools while writing a program: dump() turns any value into readable text, components() lists what is
-- connected, memory() what is left, record() shows the signals that arrive, trace() runs a function and
-- logs an error with its traceback instead of losing it
local M = {}

function M.setup(settings)
  M.settings = settings
end

---Any value as readable text (tables sorted, cycles marked)
function M.dump(value, depth, indent, seen)
  depth = depth or M.settings.depth or 4
  indent = indent or ""
  seen = seen or {}
  local kind = type(value)

  if kind == "string" then
    return string.format("%q", value)
  elseif kind ~= "table" then
    return tostring(value)
  elseif seen[value] then
    return "<cycle>"
  elseif depth <= 0 then
    return "{...}"
  end

  seen[value] = true
  local keys = {}
  for key in pairs(value) do keys[#keys + 1] = key end

  if #keys == 0 then
    seen[value] = nil
    return "{}"
  end

  table.sort(keys, function (a, b)
    if type(a) == type(b) and (type(a) == "number" or type(a) == "string") then return a < b end
    return type(a) < type(b)
  end)

  local lines = {"{"}

  for _, key in ipairs(keys) do
    local name = type(key) == "string" and key:match("^[%a_][%w_]*$") and key or ("["..M.dump(key, 1).."]")
    lines[#lines + 1] = indent.."  "..name.." = "..M.dump(value[key], depth - 1, indent.."  ", seen)..","
  end

  lines[#lines + 1] = indent.."}"
  seen[value] = nil
  return table.concat(lines, "\n")
end

---Log values at debug level (event-log shows them with logLevel "debug")
function M.log(...)
  local parts = {}

  for i = 1, select("#", ...) do
    local value = select(i, ...)
    parts[#parts + 1] = type(value) == "string" and value or M.dump(value)
  end

  require("event").push("log_debug", "[Debug] "..table.concat(parts, " "))
end

---Every component: {{type, address}}, by type
function M.components()
  local list = {}

  for address, kind in require("component").list() do
    list[#list + 1] = {type = kind, address = address}
  end

  table.sort(list, function (a, b) return a.type == b.type and a.address < b.address or a.type < b.type end)
  return list
end

---Memory: {free, total, used, percent used}
function M.memory()
  local computer = require("computer")
  local free, total = computer.freeMemory(), computer.totalMemory()
  return {free = free, total = total, used = total - free, percent = math.floor((total - free) / total * 100 + 0.5)}
end

---Collect the signals that arrive for some seconds (blocking, for a shell command). Names matching
---filter (a Lua pattern) only. Returns {{at, name, args...}}
function M.record(seconds, filter)
  local computer, event = require("computer"), require("event")
  local stopAt = computer.uptime() + seconds
  local list = {}

  while true do
    local left = stopAt - computer.uptime()

    if left <= 0 then
      break
    end

    local signal = table.pack(event.pull(left))

    if signal[1] ~= nil and (filter == nil or tostring(signal[1]):match(filter)) then
      list[#list + 1] = {at = computer.uptime(), table.unpack(signal, 1, signal.n)}
    end
  end

  return list
end

---Run a function; an error is logged with its traceback. Returns true and the results, or false and the error
function M.trace(fn, ...)
  local result = table.pack(xpcall(fn, debug.traceback, ...))

  if not result[1] then
    require("event").push("log_error", "[Debug] "..tostring(result[2]))
  end

  return table.unpack(result, 1, result.n)
end

return M
