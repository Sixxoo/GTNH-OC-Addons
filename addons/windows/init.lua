-- Pop-up windows drawn over a frame: a framed box in the middle with a title, lines and buttons.
-- The newest window is on top and gets the keys and touches; a button closes it and calls back
local M = {}

function M.setup(settings)
  M.settings = settings
end

local function ui()
  return require("addons.core").load("neon-ui")
end

local Manager = {}
Manager.__index = Manager

---A window manager (one per screen)
function M.new()
  return setmetatable({stack = {}, hits = {}}, Manager)
end

---Open a window. spec: {title, lines = {...}, color, buttons = {{key = "y", label = "Yes", id = "yes"}, ...},
---onClose = function (id)}. Without buttons Enter or Esc close it ("ok"). Returns the window
function Manager:open(spec)
  spec.buttons = spec.buttons or {{key = "enter", label = "OK", id = "ok"}}
  self.stack[#self.stack + 1] = spec
  return spec
end

---A message with an OK button
function Manager:message(title, lines, onClose)
  return self:open({title = title, lines = type(lines) == "table" and lines or {tostring(lines)}, onClose = onClose})
end

---A yes / no question: onAnswer(true or false)
function Manager:confirm(title, lines, onAnswer)
  return self:open({title = title, lines = type(lines) == "table" and lines or {tostring(lines)},
    buttons = {{key = "y", label = "Y yes", id = true}, {key = "n", label = "N no", id = false}},
    onClose = onAnswer})
end

function Manager:isOpen()
  return #self.stack > 0
end

function Manager:top()
  return self.stack[#self.stack]
end

---Close the top window with an answer (calls its onClose)
function Manager:close(id)
  local window = table.remove(self.stack)

  if window ~= nil and window.onClose then
    local isOk, problem = pcall(window.onClose, id)

    if not isOk then
      require("event").push("log_error", "[windows] "..tostring(problem))
    end
  end

  return window ~= nil
end

---Draw the windows over what is on the canvas (call last)
function Manager:draw(cv)
  local C = ui().colors
  self.hits = {}

  for index, window in ipairs(self.stack) do
    local lines = window.lines or {}
    local buttons = {}

    for _, button in ipairs(window.buttons) do
      buttons[#buttons + 1] = " "..button.label.." "
    end

    local buttonsWidth = ui().length(table.concat(buttons, " "))
    local width = math.max(ui().length(window.title or "") + 8, buttonsWidth + 4)

    for _, line in ipairs(lines) do
      width = math.max(width, ui().length(line) + 4)
    end

    width = math.min(width, cv.width - 4)
    local height = #lines + 4
    local x = math.floor((cv.width - width) / 2) + 1 + (index - 1) * 2
    local y = math.floor((cv.height - height) / 2) + 1 + (index - 1)

    -- shadow, then the box
    cv:fill(x + 1, y + 1, width, height, C.bg)
    ui().card(cv, x, y, width, height, window.title or "", {titleColor = window.color})

    for i, line in ipairs(lines) do
      cv:put(x + 2, y + i, ui().fit(line, width - 4), C.text, C.card)
    end

    local bx = x + math.floor((width - buttonsWidth) / 2)

    for i, label in ipairs(buttons) do
      local isTop = index == #self.stack
      cv:put(bx, y + height - 2, label, i == 1 and C.bg or C.neon, i == 1 and (window.color or C.neon) or C.alt)

      if isTop then
        self.hits[#self.hits + 1] = {from = bx, to = bx + ui().length(label) - 1, y = y + height - 2, id = window.buttons[i].id}
      end

      bx = bx + ui().length(label) + 1
    end
  end
end

---A key for the top window. Returns true when a window took it (keys don't reach the program then)
function Manager:key(char, code)
  local window = self:top()

  if window == nil then
    return false
  end

  local keys = require("keyboard").keys
  local key = char and char > 0 and string.char(char):lower() or nil

  for _, button in ipairs(window.buttons) do
    if (button.key == "enter" and (code == keys.enter or code == 156)) or (key ~= nil and button.key == key) then
      self:close(button.id)
      return true
    end
  end

  if code == 1 then   -- Esc: the last button
    self:close(window.buttons[#window.buttons].id)
  end

  return true
end

---A touch for the top window. Returns true when a window is open (touches don't reach the program then)
function Manager:touch(x, y)
  if not self:isOpen() then
    return false
  end

  for _, hit in ipairs(self.hits) do
    if y == hit.y and x >= hit.from and x <= hit.to then
      self:close(hit.id)
      break
    end
  end

  return true
end

return M
