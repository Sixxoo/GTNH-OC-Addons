-- Values over a long time, kept small: every value goes into each resolution (by default one point a
-- minute for 2 hours, one per 15 minutes for 2 days, one per 6 hours for 30 days). A point keeps the
-- average, lowest and highest of the values in its time. Saved to a file, by real time
local M = {}

local data, timer = {}, nil

local function clock()
  return require("addons.core").load("clock")
end

function M.setup(settings)
  M.settings = settings
  data = {}
end

local function serialize(value)
  local kind = type(value)

  if kind == "number" then
    return value == math.floor(value) and string.format("%d", value) or string.format("%.6g", value)
  elseif kind == "string" then
    return string.format("%q", value)
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

local function trim(points, level, now)
  local oldest = math.floor(now / level.seconds) - level.keep + 1

  for slot in pairs(points) do
    if slot < oldest then
      points[slot] = nil
    end
  end
end

---Add a value now (or at a real time from clock.now())
function M.add(name, value, at)
  at = at or clock().now()
  local series = data[name]

  if series == nil then
    series = {}
    data[name] = series
  end

  for index, level in ipairs(M.settings.levels) do
    local points = series[index]

    if points == nil then
      points = {}
      series[index] = points
    end

    local slot = math.floor(at / level.seconds)
    local point = points[slot]

    if point == nil then
      points[slot] = {s = value, n = 1, lo = value, hi = value}
    else
      point.s, point.n = point.s + value, point.n + 1
      point.lo, point.hi = math.min(point.lo, value), math.max(point.hi, value)
    end

    trim(points, level, at)
  end
end

---The level index for a resolution in seconds (or an index), default the finest
local function levelOf(resolution)
  if resolution == nil then
    return 1
  end

  for index, level in ipairs(M.settings.levels) do
    if index == resolution and resolution <= #M.settings.levels and resolution < 60 then
      return index
    end

    if level.seconds == resolution then
      return index
    end
  end

  return nil
end

---The last n points of a series at a resolution, oldest first: {values = averages (nil = no value then),
---low = {}, high = {}, times = {start of each point}}
---@param resolution integer|nil Seconds per point (60, 900, 21600) or the level number; default the finest
function M.series(name, resolution, n, at)
  local index = levelOf(resolution)
  assert(index ~= nil, "[history] no resolution "..tostring(resolution))
  local level = M.settings.levels[index]
  n = n or level.keep
  at = at or clock().now()

  local result = {values = {}, low = {}, high = {}, times = {}, seconds = level.seconds}
  local points = data[name] and data[name][index] or {}
  local last = math.floor(at / level.seconds)

  for i = 1, n do
    local slot = last - n + i
    local point = points[slot]
    result.times[i] = slot * level.seconds

    if point ~= nil then
      result.values[i], result.low[i], result.high[i] = point.s / point.n, point.lo, point.hi
    end
  end

  return result
end

---Names of all series
function M.names()
  local list = {}
  for name in pairs(data) do list[#list + 1] = name end
  table.sort(list)
  return list
end

function M.forget(name)
  data[name] = nil
end

function M.save()
  local path = M.settings.filePath

  if path == nil or path == "" then
    return
  end

  local file = io.open(path..".tmp", "w")

  if file == nil then
    return
  end

  file:write("return ", serialize(data), "\n")
  file:close()
  local filesystem = require("filesystem")
  filesystem.remove(path)
  filesystem.rename(path..".tmp", path)
end

function M.load()
  data = {}
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
    data = value
  end
end

---Load the file and save every saveSeconds until stop()
function M.start()
  local event = require("event")
  M.stop()
  M.load()

  timer = event.timer(M.settings.saveSeconds, function ()
    local isOk, problem = pcall(M.save)
    if not isOk then event.push("log_error", "[History] "..tostring(problem)) end
  end, math.huge)
end

function M.stop()
  if timer ~= nil then
    require("event").cancel(timer)
    timer = nil
    pcall(M.save)
  end
end

return M
