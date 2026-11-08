-- Watches a list of items and fluids (keys as in ae2: "fluid:water", "name:damage") against a minimum
-- and an optional maximum. Each check gives rows for the screen; when an entry changes state it logs
-- through the event-log signals and pushes "stock_changed" (key, state, oldState, amount)
local M = {}

local timer, last, states = nil, {}, {}

function M.setup(settings)
  M.settings = settings
  last, states = {}, {}
end

local function ae2()
  return require("addons.core").load("ae2")
end

---State of an amount against its limits: "empty", "low", "ok" or "high"
---@param amount number
---@param min number|nil
---@param max number|nil
---@return string
function M.state(amount, min, max)
  if amount <= 0 and (min or 0) > 0 then
    return "empty"
  elseif min ~= nil and amount < min then
    return "low"
  elseif max ~= nil and max > 0 and amount > max then
    return "high"
  end

  return "ok"
end

local words = {empty = "is empty", low = "is low", ok = "is fine again", high = "is over its maximum"}
local levels = {empty = "warning", low = "warning", ok = "info", high = "info"}

---Check every entry once. Rows: {key, label, amount, min, max, state, fraction (of max, else of min)}
---@param proxy table ME interface or controller
---@param list table|nil Entries, default settings.watch
---@return table[] rows
function M.check(proxy, list)
  local event = require("event")
  local rows = {}

  for _, entry in ipairs(list or M.settings.watch or {}) do
    local key = type(entry.what) == "string" and entry.what or tostring(entry.what.name or entry.what.label)
    local amount, label = ae2().stock(proxy, entry.what)
    local state = M.state(amount, entry.min, entry.max)
    local top = entry.max or entry.min

    local row = {key = key, label = entry.label or label or key, amount = amount, min = entry.min, max = entry.max,
      state = state, fraction = (top ~= nil and top > 0) and amount / top or nil}
    rows[#rows + 1] = row

    local old = states[key]

    if old ~= nil and old ~= state then
      if M.settings.logChanges and not (old == "high" and state == "ok") then
        event.push("log_"..levels[state], "[Stock] "..row.label.." "..words[state])
      end

      event.push("stock_changed", key, state, old, amount)
    end

    states[key] = state
  end

  last = rows
  return rows
end

---Rows of the last check
---@return table[]
function M.rows()
  return last
end

---Check every intervalSeconds until stop()
---@param proxy table
---@param list table|nil
function M.start(proxy, list)
  local event = require("event")
  M.stop()

  timer = event.timer(M.settings.intervalSeconds, function ()
    local isOk, problem = pcall(M.check, proxy, list)

    if not isOk then
      event.push("log_error", "[Stock] "..tostring(problem))
    end
  end, math.huge)

  pcall(M.check, proxy, list)
end

function M.stop()
  if timer ~= nil then
    require("event").cancel(timer)
    timer = nil
  end
end

return M
