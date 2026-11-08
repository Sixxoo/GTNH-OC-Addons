-- Problems that need the player, kept in one list until they are fixed. raise(key, level, text) adds or
-- updates one (logged only when it is new or its text or level changes), clear(key) removes it and logs
-- that it is fixed. Other addons raise alerts with event.push("alert_raise", key, level, text) and
-- event.push("alert_clear", key), so they don't depend on this addon. A redstone output can light a
-- lamp or sound a siren while alerts are active
local M = {}

local active, listeners, redstoneOn = {}, {}, nil
local order = {critical = 2, warning = 1}

function M.setup(settings)
  M.settings = settings
  active, redstoneOn = {}, nil
end

local function redstone(on)
  local side = M.settings.redstoneSide

  if side == nil or side == "" or redstoneOn == on then
    return
  end

  local component = require("component")
  local address = component.list("redstone")()

  if address == nil then
    return
  end

  local sides = require("sides")
  local number = type(side) == "number" and side or sides[side]

  if number ~= nil then
    pcall(component.proxy(address).setOutput, number, on and 15 or 0)
    redstoneOn = on
  end
end

local function update()
  local need = order[M.settings.redstoneLevel] or 1
  local on = false

  for _, alert in pairs(active) do
    if order[alert.level] >= need then
      on = true
    end
  end

  redstone(on)
end

---Add or update an alert. level "warning" or "critical"
---@return boolean new true when it wasn't active before
function M.raise(key, level, text)
  local event = require("event")
  level = order[level] and level or "warning"
  text = tostring(text or key)

  local old = active[key]
  active[key] = {key = key, level = level, text = text, since = old and old.since or require("computer").uptime()}

  if old == nil or old.text ~= text or old.level ~= level then
    event.push(level == "critical" and "log_error" or "log_warning", "[Alert] "..text)
    event.push("alert_changed", key, level, text)
  end

  update()
  return old == nil
end

---Remove an alert (fixed). Returns true when it was active
function M.clear(key, text)
  local old = active[key]

  if old == nil then
    return false
  end

  active[key] = nil
  local event = require("event")
  event.push("log_info", "[Alert] Fixed: "..tostring(text or old.text))
  event.push("alert_changed", key, nil, nil)
  update()
  return true
end

---Active alerts, critical first, then oldest first: {key, level, text, since}
function M.list()
  local list = {}

  for _, alert in pairs(active) do
    list[#list + 1] = alert
  end

  table.sort(list, function (a, b)
    if a.level ~= b.level then return order[a.level] > order[b.level] end
    return a.since < b.since
  end)

  return list
end

function M.count()
  local n = 0
  for _ in pairs(active) do n = n + 1 end
  return n
end

---"critical", "warning" or nil
function M.worst()
  local first = M.list()[1]
  return first and first.level or nil
end

function M.isActive(key)
  return active[key] ~= nil
end

---Take alerts pushed as signals (alert_raise, alert_clear) until stop()
function M.start()
  local event = require("event")
  M.stop()

  listeners[1] = event.listen("alert_raise", function (_, key, level, text)
    pcall(M.raise, key, level, text)
  end)
  listeners[2] = event.listen("alert_clear", function (_, key, text)
    pcall(M.clear, key, text)
  end)
end

---Stop listening and switch the redstone off
function M.stop()
  for _, id in ipairs(listeners) do
    require("event").cancel(id)
  end

  listeners = {}
  redstone(false)
end

return M
