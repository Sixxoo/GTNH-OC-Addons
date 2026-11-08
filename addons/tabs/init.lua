-- Pages on one screen. A tab row drawn in the neon style (the open tab as a filled label), switched by
-- Tab / Shift+Tab, the left and right arrows, number keys or a touch on the row. The program draws the
-- page of tabs:current() and calls tabs:draw where the row goes, e.g. on the header line
local M = {}

function M.setup(settings)
  M.settings = settings
end

local function ui()
  return require("addons.core").load("neon-ui")
end

local Tabs = {}
Tabs.__index = Tabs

---A tab row. pages: {{id = "overview", title = "OVERVIEW"}, ...}
---@param pages table[]
---@return table tabs
function M.new(pages)
  assert(type(pages) == "table" and #pages > 0, "[tabs] give at least one page: {{id, title}, ...}")
  return setmetatable({pages = pages, selected = 1, hits = {}, listeners = {}}, Tabs)
end

---Id of the open tab
function Tabs:current()
  return self.pages[self.selected].id
end

---Number of the open tab
function Tabs:index()
  return self.selected
end

---Open a tab by id or number. Returns true when it changed
---@param which string|integer
---@return boolean
function Tabs:select(which)
  local index = which

  if type(which) ~= "number" then
    for i, page in ipairs(self.pages) do
      if page.id == which then
        index = i
      end
    end
  end

  if type(index) ~= "number" or self.pages[index] == nil or index == self.selected then
    return false
  end

  self.selected = index

  if self.onChange then
    self.onChange(self:current(), index)
  end

  return true
end

function Tabs:next()
  return self:select(self.selected % #self.pages + 1)
end

function Tabs:prev()
  return self:select((self.selected - 2) % #self.pages + 1)
end

---Width of the row in cells
function Tabs:width()
  local width = 0

  for i, page in ipairs(self.pages) do
    width = width + ui().length(" "..i.." "..page.title.." ") + 1
  end

  return width - 1
end

---Draw the row: the open tab as a filled label, the others dim, each with its number
---@param cv table neon-ui canvas
---@param x integer
---@param y integer
---@param bg number|nil Background of the row (default the screen background)
function Tabs:draw(cv, x, y, bg)
  local C = ui().colors
  bg = bg or C.bg
  self.hits = {}

  for i, page in ipairs(self.pages) do
    local label = " "..i.." "..page.title.." "
    local length = ui().length(label)

    if i == self.selected then
      cv:put(x, y, label, C.bg, C.neon)
    else
      cv:put(x, y, " ", C.na, bg)
      cv:put(x + 1, y, tostring(i), C.neon, bg)
      cv:put(x + 2, y, " "..page.title.." ", C.na, bg)
    end

    self.hits[#self.hits + 1] = {from = x, to = x + length - 1, y = y, index = i}
    x = x + length + 1
  end
end

---A key from key_down (char, code). Returns true when the tab changed
---@param char number
---@param code number
---@return boolean
function Tabs:key(char, code)
  local keyboard = require("keyboard")
  local keys = keyboard.keys

  if code == keys.tab then
    if keyboard.isShiftDown and keyboard.isShiftDown() then
      return self:prev()
    end

    return self:next()
  elseif M.settings.arrows and code == keys.right then
    return self:next()
  elseif M.settings.arrows and code == keys.left then
    return self:prev()
  elseif M.settings.numbers and char ~= nil and char >= 49 and char <= 57 then
    return self:select(char - 48)
  end

  return false
end

---A touch at a cell. Returns true when it hit a tab and the tab changed
---@param x number
---@param y number
---@return boolean
function Tabs:touch(x, y)
  for _, hit in ipairs(self.hits) do
    if y == hit.y and x >= hit.from and x <= hit.to then
      return self:select(hit.index)
    end
  end

  return false
end

---Listen to keys and touches until stop(); onChange(id, index) is called after a change
---@param onChange function|nil
function Tabs:listen(onChange)
  local event = require("event")
  self:stop()
  self.onChange = onChange or self.onChange

  self.listeners[#self.listeners + 1] = event.listen("key_down", function (_, _, char, code)
    pcall(self.key, self, char, code)
  end)
  self.listeners[#self.listeners + 1] = event.listen("touch", function (_, _, x, y)
    pcall(self.touch, self, math.floor(x), math.floor(y))
  end)
end

function Tabs:stop()
  local event = require("event")

  for _, id in ipairs(self.listeners) do
    event.cancel(id)
  end

  self.listeners = {}
end

return M
