-- Touch areas on a screen: draw buttons while drawing a frame, then a touch tells which one was hit.
-- Areas are set again with every frame (clear, then draw), so they always match what is shown
local M = {}

function M.setup(settings)
  M.settings = settings
end

local function ui()
  return require("addons.core").load("neon-ui")
end

local Panel = {}
Panel.__index = Panel

---A set of touch areas
---@return table panel
function M.new()
  return setmetatable({areas = {}, listeners = {}, last = {}}, Panel)
end

---Forget the areas (call before drawing a new frame)
function Panel:clear()
  self.areas = {}
end

---A touch area without drawing anything. Later areas win where they overlap
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param id any What hit() returns
function Panel:area(x, y, w, h, id)
  self.areas[#self.areas + 1] = {x = x, y = y, w = w, h = h, id = id}
end

---Draw a button "[ text ]" and make it touchable. Returns its width
---@param cv table neon-ui canvas
---@param options table|nil {color, active = bool (filled), disabled = bool}
---@return integer width
function Panel:button(cv, x, y, text, id, options)
  options = options or {}
  local C = ui().colors
  local label = " "..text.." "
  local width = ui().length(label)

  if options.disabled then
    cv:put(x, y, label, C.na, C.alt)
    return width
  end

  local color = options.color or C.neon

  if options.active then
    cv:put(x, y, label, C.bg, color)
  else
    cv:put(x, y, label, color, C.alt)
  end

  self:area(x, y, width, 1, id)
  return width
end

---Which area is at a cell, or nil
function Panel:hit(x, y)
  for i = #self.areas, 1, -1 do
    local a = self.areas[i]

    if x >= a.x and x < a.x + a.w and y >= a.y and y < a.y + a.h then
      return a.id
    end
  end

  return nil
end

---Handle a touch: the id of the area, or nil (also for a repeat within repeatSeconds)
function Panel:press(x, y)
  local id = self:hit(x, y)

  if id == nil then
    return nil
  end

  local now = require("computer").uptime()

  if self.last.id == id and now - self.last.at < (M.settings.repeatSeconds or 0.3) then
    return nil
  end

  self.last = {id = id, at = now}
  return id
end

---Call onPress(id, x, y, button, player) for touches on areas until stop()
function Panel:listen(onPress)
  local event = require("event")
  self:stop()

  self.listeners[1] = event.listen("touch", function (_, _, x, y, button, player)
    local isOk, id = pcall(self.press, self, math.floor(x), math.floor(y))

    if isOk and id ~= nil then
      local done, problem = pcall(onPress, id, x, y, button, player)

      if not done then
        event.push("log_error", "[touch] "..tostring(problem))
      end
    end
  end)
end

function Panel:stop()
  for _, id in ipairs(self.listeners) do
    require("event").cancel(id)
  end

  self.listeners = {}
end

return M
