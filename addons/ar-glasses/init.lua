-- Lines on the HUD of AR glasses through an OpenGlasses glasses terminal (component "glasses").
-- set(key, text, color) keeps one line per key and only changes what changed, so the server isn't
-- asked to remake widgets every update. Every glasses call is guarded: an API that differs only
-- turns that piece off, the program keeps running
local M = {}

local lines, order, box = {}, {}, nil

function M.setup(settings)
  M.settings = settings
  lines, order, box = {}, {}, nil
end

---The glasses terminal, or nil and why
function M.find()
  local component = require("component")
  local address = component.list("glasses")()

  if address == nil then
    return nil, "[ar-glasses] no glasses terminal (component glasses) on the network"
  end

  return component.proxy(address)
end

local function rgb(color)
  return ((color >> 16) & 0xFF) / 255, ((color >> 8) & 0xFF) / 255, (color & 0xFF) / 255
end

local function call(object, name, ...)
  if object ~= nil and object[name] ~= nil then
    return pcall(object[name], ...)
  end

  return false
end

local function layout()
  local s = M.settings

  if box ~= nil then
    call(box, "setSize", 220, #order * s.lineHeight + 4)
  end

  for i, key in ipairs(order) do
    call(lines[key].widget, "setPosition", s.x + 2, s.y + 2 + (i - 1) * s.lineHeight)
  end
end

---Show or change a HUD line. color 0xRRGGBB
---@return boolean ok
function M.set(key, text, color)
  local glasses = M.find()

  if glasses == nil then
    return false
  end

  local s = M.settings
  local line = lines[key]

  if box == nil and s.background > 0 then
    local isOk, widget = call(glasses, "addRect")

    if isOk and widget ~= nil then
      box = widget
      call(box, "setPosition", s.x, s.y)
      call(box, "setColor", 0, 0, 0)
      call(box, "setAlpha", s.background)
    end
  end

  if line == nil then
    local isOk, widget = call(glasses, "addTextLabel")

    if not isOk or widget == nil then
      return false
    end

    line = {widget = widget}
    lines[key] = line
    order[#order + 1] = key
    call(widget, "setScale", s.scale)
    layout()
  end

  if line.text ~= text then
    call(line.widget, "setText", tostring(text))
    line.text = text
  end

  color = color or 0xFFFFFF

  if line.color ~= color then
    call(line.widget, "setColor", rgb(color))
    line.color = color
  end

  return true
end

---Remove one HUD line
function M.remove(key)
  local line = lines[key]

  if line == nil then
    return
  end

  local glasses = M.find()
  call(line.widget, "delete")

  if glasses ~= nil and line.widget.getID then
    local isOk, id = pcall(line.widget.getID)
    if isOk then call(glasses, "removeObject", id) end
  end

  lines[key] = nil

  for i, name in ipairs(order) do
    if name == key then
      table.remove(order, i)
      break
    end
  end

  layout()
end

---Remove everything this addon put on the HUD
function M.clear()
  local glasses = M.find()
  call(glasses, "removeAll")
  lines, order, box = {}, {}, nil
end

---Players who wear glasses linked to the terminal (names), if the terminal tells
function M.players()
  local glasses = M.find()
  local isOk, list = call(glasses, "getBindPlayers")
  return isOk and type(list) == "table" and list or {}
end

return M
