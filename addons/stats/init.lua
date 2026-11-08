-- Statistics that survive restarts. Counters (cycles, crafts...) keep a total and a sum per hour;
-- readings (a stock, power...) keep last, min, max and average per hour. History is kept for
-- keepHours, by real time, and saved to a small file. Uptime counts this run and all runs together
local M = {}

local data, timer, startedAt = nil, nil, nil

local function clock()
  return require("addons.core").load("clock")
end

local function hour(at)
  return math.floor((at or clock().now()) / 3600)
end

local function empty()
  return {counters = {}, readings = {}, uptime = 0, since = nil}
end

function M.setup(settings)
  M.settings = settings
  data, startedAt = empty(), nil
end

-- ---------- file ----------

local function serialize(value)
  local kind = type(value)

  if kind == "string" then
    return string.format("%q", value)
  elseif kind == "number" then
    return value == math.floor(value) and string.format("%d", value) or string.format("%.6g", value)
  elseif kind == "boolean" then
    return tostring(value)
  elseif kind ~= "table" then
    return "nil"
  end

  local parts = {}

  for key, item in pairs(value) do
    local name = type(key) == "string" and key:match("^[%a_][%w_]*$") and key or ("["..serialize(key).."]")
    parts[#parts + 1] = name.."="..serialize(item)
  end

  return "{"..table.concat(parts, ",").."}"
end

local function trim(entry)
  local oldest = hour() - M.settings.keepHours + 1

  for at in pairs(entry.hours) do
    if at < oldest then
      entry.hours[at] = nil
    end
  end
end

---Write the statistics to the file now
function M.save()
  local path = M.settings.filePath

  if path == nil or path == "" then
    return
  end

  local copy = {counters = data.counters, readings = data.readings, since = data.since,
    uptime = data.uptime + (startedAt and clock().since(startedAt) or 0)}
  local file = io.open(path..".tmp", "w")

  if file == nil then
    return
  end

  file:write("return ", serialize(copy), "\n")
  file:close()

  local filesystem = require("filesystem")
  filesystem.remove(path)
  filesystem.rename(path..".tmp", path)
end

---Read the file (a broken or missing file starts empty)
function M.load()
  data = empty()
  local path = M.settings.filePath
  local file = path ~= nil and path ~= "" and io.open(path, "r") or nil

  if file == nil then
    return
  end

  local text = file:read("*a")
  file:close()

  local chunk = load(text, "="..path, "t", {})
  local isOk, value = false, nil

  if chunk ~= nil then
    isOk, value = pcall(chunk)
  end

  if isOk and type(value) == "table" then
    data.counters = type(value.counters) == "table" and value.counters or {}
    data.readings = type(value.readings) == "table" and value.readings or {}
    data.uptime = tonumber(value.uptime) or 0
    data.since = tonumber(value.since)

    for _, entry in pairs(data.counters) do entry.hours = entry.hours or {} trim(entry) end
    for _, entry in pairs(data.readings) do entry.hours = entry.hours or {} trim(entry) end
  end
end

-- ---------- counters ----------

local function counter(name)
  local entry = data.counters[name]

  if entry == nil then
    entry = {total = 0, hours = {}}
    data.counters[name] = entry
  end

  return entry
end

---Count something, e.g. M.add("cycles") or M.add("crafted", 64)
---@param name string
---@param amount number|nil default 1
function M.add(name, amount)
  amount = amount or 1
  local entry = counter(name)
  local at = hour()
  entry.total = entry.total + amount
  entry.hours[at] = (entry.hours[at] or 0) + amount
  trim(entry)
end

---All-time total of a counter
function M.total(name)
  local entry = data.counters[name]
  return entry and entry.total or 0
end

---Sum of a counter over the last n hours (this hour counts as one)
function M.last(name, hours)
  local entry, sum = data.counters[name], 0

  if entry == nil then
    return 0
  end

  local now = hour()

  for at, value in pairs(entry.hours) do
    if at > now - (hours or 24) then
      sum = sum + value
    end
  end

  return sum
end

---Per hour over the last n hours, counting only the time the program ran (no more than n hours)
function M.rate(name, hours)
  hours = hours or 24
  local ran = math.min(hours * 3600, M.uptime().total)

  if ran < 60 then
    return 0
  end

  return M.last(name, hours) / ran * 3600
end

-- ---------- readings ----------

---Record a reading, e.g. M.record("water.t1", 31500000)
---@param name string
---@param value number
function M.record(name, value)
  local entry = data.readings[name]

  if entry == nil then
    entry = {hours = {}}
    data.readings[name] = entry
  end

  local at = hour()
  local slot = entry.hours[at]

  if slot == nil then
    slot = {min = value, max = value, sum = 0, n = 0}
    entry.hours[at] = slot
  end

  slot.min, slot.max = math.min(slot.min, value), math.max(slot.max, value)
  slot.sum, slot.n, slot.last = slot.sum + value, slot.n + 1, value
  entry.last = value
  trim(entry)
end

---A reading over the last n hours: {last, min, max, avg, first (average of the oldest hour)}, nil when none
function M.reading(name, hours)
  local entry = data.readings[name]

  if entry == nil then
    return nil
  end

  local now, result, sum, n, oldest = hour(), {last = entry.last}, 0, 0, nil

  for at, slot in pairs(entry.hours) do
    if at > now - (hours or 24) then
      result.min = result.min and math.min(result.min, slot.min) or slot.min
      result.max = result.max and math.max(result.max, slot.max) or slot.max
      sum, n = sum + slot.sum, n + slot.n

      if oldest == nil or at < oldest then
        oldest, result.first = at, slot.sum / slot.n
      end
    end
  end

  result.avg = n > 0 and sum / n or nil
  return result
end

-- ---------- history ----------

---Values of the last n hours, oldest first (this hour last): counter sums, or reading averages
---(nil for hours without a reading)
---@return table values
function M.hours(name, n)
  n = n or 24
  local entry = data.counters[name] or data.readings[name]
  local list, now = {}, hour()

  for i = 1, n do
    local at = now - n + i
    local value = entry and entry.hours[at]

    if type(value) == "table" then
      value = value.sum / value.n
    elseif value == nil and data.counters[name] then
      value = 0
    end

    list[i] = value
  end

  return list
end

-- ---------- uptime ----------

---{session = seconds of this run, total = all runs, since = real time of the first run}
function M.uptime()
  local session = startedAt and clock().since(startedAt) or 0
  return {session = session, total = data.uptime + session, since = data.since}
end

---Forget one counter or reading, or everything
function M.reset(name)
  if name == nil then
    data = empty()
    data.since = startedAt and clock().now() or nil
  else
    data.counters[name], data.readings[name] = nil, nil
  end
end

---Load the file, count uptime and save every saveSeconds until stop()
function M.start()
  local event = require("event")
  M.stop()
  M.load()
  startedAt = clock().now()
  data.since = data.since or startedAt

  timer = event.timer(M.settings.saveSeconds, function ()
    local isOk, problem = pcall(M.save)

    if not isOk then
      event.push("log_error", "[Stats] "..tostring(problem))
    end
  end, math.huge)
end

---Save and stop saving
function M.stop()
  if timer ~= nil then
    require("event").cancel(timer)
    timer = nil
  end

  if startedAt ~= nil then
    pcall(M.save)
    data.uptime = data.uptime + clock().since(startedAt)
    startedAt = nil
  end
end

return M
