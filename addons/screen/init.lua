-- Shows whole frames on the screen: lines with colour codes, only the rows that changed are sent.
-- Fits the resolution to the screen's shape and binds the screen again if it was lost
local M = {}

local width, height = 80, 25
local shown = nil        -- lines on the screen, nil when everything must be drawn again
local fullAt = nil       -- uptime of the last full frame

function M.setup(settings)
  M.settings = settings
end

local function gpu()
  return require("component").gpu
end

---Bind the GPU to a screen again if it lost it. A screen that leaves the network (a broken cable)
---is unbound, and stays unbound when it comes back
---@return boolean # true if it was bound again
function M.ensureScreen()
  local component = require("component")
  local card = component.gpu

  if card.getScreen() ~= nil then
    return false
  end

  local screen = component.list("screen")()

  if screen == nil then
    return false
  end

  card.bind(screen)
  card.setResolution(width, height)
  shown = nil

  return true
end

---Width for a number of rows that fills the screen: a character cell is twice as tall as wide
---@param rows integer
---@return integer width
---@return integer height
function M.fit(rows)
  local card = gpu()
  local maxWidth, maxHeight = card.maxResolution()
  local h = math.min(rows, maxHeight)
  local w = math.min(M.settings and M.settings.minWidth or 80, maxWidth)

  local isOk, a, b = pcall(function ()
    return require("component").proxy(card.getScreen()).getAspectRatio()
  end)

  if isOk and type(a) == "number" and type(b) == "number" and a > 0 and b > 0 then
    w = math.max(w, math.min(math.floor(h * 2 * a / b + 0.5), maxWidth))
  end

  return w, h
end

---Set the resolution and start with a full frame
---@param rows? integer Rows to use, default from settings
---@return integer width
---@return integer height
function M.open(rows)
  M.ensureScreen()
  width, height = M.fit(rows or M.settings.rows)
  gpu().setResolution(width, height)
  shown = nil
  return width, height
end

---@return integer width
---@return integer height
function M.size()
  return width, height
end

---Draw everything again with the next frame
function M.redraw()
  shown = nil
end

---Draw one line with colour codes: &0xRRGGBB; foreground, &&0xRRGGBB; background. Text in one colour is one call
local function drawLine(card, line, y)
  local foreground, background = 0xFFFFFF, 0x000000
  local x, i, run = 1, 1, {}

  card.setForeground(foreground)
  card.setBackground(background)

  local function flush()
    if #run > 0 then
      local text = table.concat(run)
      card.set(x, y, text)
      x = x + #run
      run = {}
    end
  end

  while i <= #line do
    local code = line:match("^&&?(0x%x+);", i)

    if code ~= nil then
      local isBackground = line:sub(i + 1, i + 1) == "&"
      local color = tonumber(code)

      if isBackground and color ~= background then
        flush()
        background = color
        card.setBackground(color)
      elseif not isBackground and color ~= foreground then
        flush()
        foreground = color
        card.setForeground(color)
      end

      i = i + #code + (isBackground and 3 or 2)
    else
      local char = line:match("^[%z\1-\127\194-\244][\128-\191]*", i)
      run[#run + 1] = char
      i = i + #char
    end
  end

  flush()
end

---Show a frame: one line per row. Only rows that changed are drawn, into a buffer, then copied to the screen
---@param lines string[]
function M.show(lines)
  if M.ensureScreen() then
    shown = nil
  end

  local now = require("computer").uptime()
  local every = M.settings and M.settings.fullRedrawSeconds or 60

  -- Now and then everything again, in case something else wrote on the screen
  if fullAt == nil or now - fullAt >= every or now < fullAt then
    shown = nil
  end

  local changed = {}

  for y = 1, height do
    if shown == nil or shown[y] ~= lines[y] then
      changed[#changed + 1] = y
    end
  end

  if shown == nil then
    fullAt = now
  end

  shown = lines

  if #changed == 0 then
    return 0
  end

  local card = gpu()
  local buffer = card.allocateBuffer(width, height)

  if buffer == nil then
    -- No video memory left: draw straight on the screen
    for _, y in ipairs(changed) do
      drawLine(card, lines[y] or "", y)
    end

    return #changed
  end

  local isOk, problem = pcall(function ()
    card.setActiveBuffer(buffer)

    for _, y in ipairs(changed) do
      drawLine(card, lines[y] or "", y)
    end

    card.setActiveBuffer(0)

    for _, y in ipairs(changed) do
      card.bitblt(0, 1, y, width, 1, buffer, 1, y)
    end
  end)

  card.setActiveBuffer(0)
  card.freeBuffer(buffer)

  if not isOk then
    shown = nil
    error("[screen] "..tostring(problem), 0)
  end

  return #changed
end

---Give the screen back: largest resolution, cleared
function M.close()
  local card = gpu()
  local w, h = card.maxResolution()
  card.setActiveBuffer(0)
  card.setResolution(w, h)
  card.setForeground(0xFFFFFF)
  card.setBackground(0x000000)
  card.fill(1, 1, w, h, " ")
  shown = nil
end

return M
