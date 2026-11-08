-- How fast items come in: samples the amounts of the filtered items now and then (real time) and gives
-- items per hour over the window, per item and in total. Each filter is one getItemsInNetwork call
-- filtered by the network itself, so even a big network isn't scanned whole
local M = {}

local timer, samples = nil, {}

function M.setup(settings)
  M.settings = settings
  samples = {}
end

local function ae2()
  return require("addons.core").load("ae2")
end

local function clock()
  return require("addons.core").load("clock")
end

---Take one sample now (or at a given real time from clock.now())
---@param proxy table
---@param at number|nil
function M.sample(proxy, at)
  local amounts = {}

  for _, filter in ipairs(M.settings.filters or {}) do
    for _, stack in ipairs(ae2().items(proxy, filter)) do
      local seen = amounts[stack.key]
      amounts[stack.key] = {label = stack.label, size = (seen and seen.size or 0) + stack.size}
    end
  end

  at = at or clock().now()
  samples[#samples + 1] = {at = at, amounts = amounts}

  -- keep one sample older than the window, so the rate covers the whole window
  local window = M.settings.windowMinutes * 60

  while #samples > 2 and at - samples[2].at >= window do
    table.remove(samples, 1)
  end
end

---Items per hour over the window, fastest first: {rows = {{key, label, perHour, gained, amount}}, perHour,
---minutes (what the rates cover; 0 until two samples)}
---@return table
function M.rates()
  local result = {rows = {}, perHour = 0, minutes = 0}

  if #samples < 2 then
    return result
  end

  local first, last = samples[1], samples[#samples]
  local hours = (last.at - first.at) / 3600

  if hours <= 0 then
    return result
  end

  for key, now in pairs(last.amounts) do
    local before = first.amounts[key]
    local gained = now.size - (before and before.size or 0)

    if gained ~= 0 then
      result.rows[#result.rows + 1] = {key = key, label = now.label, gained = gained, amount = now.size,
        perHour = gained / hours}
    end
  end

  for key, before in pairs(first.amounts) do
    if last.amounts[key] == nil then
      result.rows[#result.rows + 1] = {key = key, label = before.label, gained = -before.size, amount = 0,
        perHour = -before.size / hours}
    end
  end

  table.sort(result.rows, function (a, b) return a.perHour > b.perHour end)

  for _, row in ipairs(result.rows) do
    if row.perHour > 0 then
      result.perHour = result.perHour + row.perHour
    end
  end

  result.minutes = (last.at - first.at) / 60
  return result
end

function M.clear()
  samples = {}
end

---Sample every intervalSeconds until stop()
---@param proxy table
function M.start(proxy)
  local event = require("event")
  M.stop()

  timer = event.timer(M.settings.intervalSeconds, function ()
    local isOk, problem = pcall(M.sample, proxy)

    if not isOk then
      event.push("log_error", "[Yield] "..tostring(problem))
    end
  end, math.huge)

  pcall(M.sample, proxy)
end

function M.stop()
  if timer ~= nil then
    require("event").cancel(timer)
    timer = nil
  end
end

return M
