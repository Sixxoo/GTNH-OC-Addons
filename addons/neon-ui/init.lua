-- The neon style as building blocks: a canvas of cells, cards with blue frames and red corners,
-- bars with a red slider, label/value rows, header and footer. A program builds its own layout from them;
-- canvas:lines() gives the lines for the screen addon
local M = {}

---Default colours. A program or /home/addons.cfg can change any of them with the setting theme
M.defaults = {
  bg = 0x03050A, card = 0x090C14, face = 0x0B0F18, alt = 0x101826,
  neon = 0x00B4FF, red = 0xFF2A3D, green = 0x2BE05A, amber = 0xFFB020, yellow = 0xFFE14D,
  orange = 0xFF8A1F, cyan = 0x2EF0F0,
  text = 0xFFFFFF, dim = 0xB9C7DB, sub = 0xA9D4FF, na = 0x6B7A8F, track = 0x1E2C40, line = 0x14507A,
}

M.colors = {}

local CH = {
  tl = "┌", tr = "┐", bl = "└", br = "┘", h = "─", v = "│", heavy = "━",
  lt = "├", rt = "┤", mark = "┃",
}
M.chars = CH

local corners = true

---@param settings table {theme = {name = 0xRRGGBB, ...}, corners = boolean}
function M.setup(settings)
  M.colors = {}

  for name, value in pairs(M.defaults) do
    M.colors[name] = value
  end

  for name, value in pairs(settings.theme or {}) do
    M.colors[name] = value
  end

  corners = settings.corners ~= false

  -- Colour names used in log lines (&white; ...), in the neon colours
  M.logPalette = {
    white = M.colors.text, lightGray = M.colors.na, gray = M.colors.na, yellow = M.colors.amber,
    red = M.colors.red, cyan = M.colors.neon, green = M.colors.green, lime = M.colors.green,
    darkOrange = M.colors.orange,
  }
end

M.setup({})

-- ---------- text ----------

---Split UTF-8 text into characters. The screen font draws every character used here one cell wide
---@param text string
---@return string[]
function M.split(text)
  local list = {}

  for char in tostring(text):gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    list[#list + 1] = char
  end

  return list
end

---Length in cells
function M.length(text)
  return #M.split(text)
end

---Shorten text to a width, with a dot at the end when it was cut
function M.fit(text, width)
  local list = M.split(text)

  if #list <= width then
    return tostring(text)
  end

  if width <= 1 then
    return table.concat(list, "", 1, math.max(0, width))
  end

  return table.concat(list, "", 1, width - 1).."."
end

---"1h 05m" or "4m 07s"
function M.duration(seconds)
  seconds = math.max(0, math.floor(seconds))
  local hours, minutes = math.floor(seconds / 3600), math.floor(seconds % 3600 / 60)

  if hours > 0 then
    return string.format("%dh %02dm", hours, minutes)
  end

  return string.format("%dm %02ds", minutes, seconds % 60)
end

---Colour for a value from steps tried in order: {{below = 1e6, color = red}, {below = 8e6, color = orange}}.
---The first step whose `below` the value is under wins; otherwise `otherwise`
function M.levelColor(value, steps, otherwise)
  for _, step in ipairs(steps) do
    if step.below ~= nil and value < step.below then
      return step.color
    end
  end

  return otherwise or M.colors.green
end

-- ---------- canvas ----------

---@class NeonCanvas
local canvas = {}
canvas.__index = canvas

---A grid of cells to draw on
---@param width integer
---@param height integer
---@return NeonCanvas
function M.canvas(width, height)
  local self = setmetatable({width = width, height = height, char = {}, fg = {}, bg = {}}, canvas)

  for y = 1, height do
    self.char[y], self.fg[y], self.bg[y] = {}, {}, {}

    for x = 1, width do
      self.char[y][x], self.fg[y][x], self.bg[y][x] = " ", M.colors.text, M.colors.bg
    end
  end

  return self
end

---Write text. With a width it is padded or cut to it. A nil background keeps what is there
function canvas:put(x, y, text, fg, bg, width)
  if y < 1 or y > self.height then
    return
  end

  local list = M.split(text)

  if width ~= nil then
    while #list < width do
      list[#list + 1] = " "
    end
  end

  for i, char in ipairs(list) do
    if width ~= nil and i > width then
      break
    end

    local cx = x + i - 1

    if cx >= 1 and cx <= self.width then
      self.char[y][cx] = char
      self.fg[y][cx] = fg or M.colors.text

      if bg ~= nil then
        self.bg[y][cx] = bg
      end
    end
  end
end

---Fill a rectangle with a background
function canvas:fill(x, y, width, height, bg)
  for row = y, y + height - 1 do
    self:put(x, row, string.rep(" ", width), M.colors.text, bg)
  end
end

---Write text with colour names or numbers (&white; or &0xRRGGBB;), cut to a width
function canvas:putCoded(x, y, text, width, bg, palette)
  palette = palette or M.logPalette
  local fg = M.colors.text
  local column, i = 0, 1

  while i <= #text and column < width do
    local code = text:match("^&&?([^;]*);", i)

    if code ~= nil then
      local isBackground = text:sub(i + 1, i + 1) == "&"
      local color = palette[code] or tonumber(code)

      if color ~= nil and not isBackground then
        fg = color
      end

      i = i + #code + (isBackground and 3 or 2)
    else
      local char = text:match("^[%z\1-\127\194-\244][\128-\191]*", i)
      self:put(x + column, y, char, fg, bg)
      column = column + 1
      i = i + #char
    end
  end
end

---The rows as lines with colour codes, for the screen addon
---@return string[]
function canvas:lines()
  local lines = {}

  for y = 1, self.height do
    local parts, fg, bg = {}, nil, nil

    for x = 1, self.width do
      local char = self.char[y][x]

      if self.bg[y][x] ~= bg then
        bg = self.bg[y][x]
        parts[#parts + 1] = string.format("&&0x%06X;", bg)
      end

      -- A space shows only its background, so its foreground needs no code
      if char ~= " " and self.fg[y][x] ~= fg then
        fg = self.fg[y][x]
        parts[#parts + 1] = string.format("&0x%06X;", fg)
      end

      parts[#parts + 1] = char
    end

    lines[y] = table.concat(parts)
  end

  return lines
end

-- ---------- pieces ----------

---Top edge of a card: title on the left, a value on the right
---@param options? table {right = text, rightColor = colour, titleColor = colour}
function M.cardTop(cv, x, y, w, title, options)
  options = options or {}
  local C = M.colors

  cv:put(x, y, CH.tl..string.rep(CH.h, w - 2)..CH.tr, C.neon, C.card)

  if corners then
    cv:put(x, y, CH.tl, C.red, C.card)
  end

  if title ~= nil and title ~= "" then
    cv:put(x + 2, y, " "..title.." ", options.titleColor or C.text, C.card)
  end

  if options.right ~= nil and options.right ~= "" then
    local text = " "..options.right.." "
    cv:put(x + w - 2 - M.length(text), y, text, options.rightColor or C.dim, C.card)
  end
end

---A card: filled, framed, with a title and an optional value at the top right
---@param options? table {right, rightColor, titleColor}
function M.card(cv, x, y, w, h, title, options)
  local C = M.colors

  cv:fill(x, y, w, h, C.card)
  M.cardTop(cv, x, y, w, title, options)
  cv:put(x, y + h - 1, CH.bl..string.rep(CH.h, w - 2)..CH.br, C.neon, C.card)

  if corners then
    cv:put(x + w - 1, y + h - 1, CH.br, C.red, C.card)
  end

  for row = y + 1, y + h - 2 do
    cv:put(x, row, CH.v, C.neon, C.card)
    cv:put(x + w - 1, row, CH.v, C.neon, C.card)
  end
end

---A line across a card, joined to its frame
function M.divider(cv, x, y, w)
  cv:put(x, y, CH.lt..string.rep(CH.h, w - 2)..CH.rt, M.colors.neon, M.colors.card)
end

---A thin bar: heavy line up to the fraction, light line for the rest, and a red slider at the fraction
---@param options? table {color, track, slider = true, sliderColor}
---@return number fraction The fraction, kept between 0 and 1
function M.bar(cv, x, y, w, fraction, options)
  options = options or {}
  local C = M.colors
  fraction = math.max(0, math.min(1, fraction or 0))
  local filled = math.floor(fraction * w + 0.5)

  cv:put(x, y, string.rep(CH.heavy, filled), options.color or C.neon, options.bg)
  cv:put(x + filled, y, string.rep(CH.h, w - filled), options.track or C.track, options.bg)

  if options.slider ~= false then
    local position = math.min(w - 1, math.floor(fraction * w))
    cv:put(x + position, y, CH.mark, options.sliderColor or C.red, options.bg)
  end

  return fraction
end

---A row: label on the left, value on the right
function M.row(cv, x, y, w, label, value, valueColor, bg)
  cv:put(x, y, M.fit(label, w), M.colors.dim, bg)

  if value ~= nil then
    local text = M.fit(value, w - M.length(label) - 1)
    cv:put(x + w - M.length(text), y, text, valueColor or M.colors.text, bg)
  end
end

---A filled label like " BALANCING "
function M.badge(cv, x, y, text, color)
  cv:put(x, y, " "..text.." ", M.colors.bg, color or M.colors.neon)
end

---Header over the first two rows: clock, title and author, status; then a line with a badge and the version
---@param options table {clock, title, by, status, statusColor, badge, badgeColor, version}
function M.header(cv, options)
  local C = M.colors
  local W = cv.width

  if options.clock then
    cv:put(2, 1, options.clock, C.na, C.bg)
  end

  local title, by = options.title or "", options.by
  local length = M.length(title) + (by and (M.length(by) + 1) or 0)
  local titleX = math.floor((W - length) / 2) + 1
  cv:put(titleX, 1, title, C.text, C.bg)

  if by then
    cv:put(titleX + M.length(title) + 1, 1, by, C.neon, C.bg)
  end

  if options.status then
    local label = "[ "..options.status.." ]"
    cv:put(W - M.length(label), 1, label, options.statusColor or C.green, C.bg)
  end

  cv:put(1, 2, string.rep(CH.h, W), C.line, C.bg)

  if options.badge then
    M.badge(cv, 2, 2, options.badge, options.badgeColor)
  end

  if options.version then
    local version = " v"..options.version.." "
    cv:put(W - M.length(version), 2, version, C.na, C.bg)
  end
end

---Footer on the last row: keys on the left, a legend on the right
---@param options table {keys = {{"Q", "quit"}, ...}, legend = {{"▶", "next", colour}, ...}}
function M.footer(cv, options)
  local C = M.colors
  local y = cv.height
  local column = 2

  for _, key in ipairs(options.keys or {}) do
    cv:put(column, y, key[1], C.neon, C.bg)
    cv:put(column + M.length(key[1]) + 1, y, key[2], C.na, C.bg)
    column = column + M.length(key[1]) + M.length(key[2]) + 4
  end

  local legend = options.legend or {}
  local width = 0

  for _, item in ipairs(legend) do
    width = width + M.length(item[1]) + 1 + M.length(item[2]) + 3
  end

  column = cv.width - width + 2

  for _, item in ipairs(legend) do
    cv:put(column, y, item[1], item[3] or C.neon, C.bg)
    cv:put(column + M.length(item[1]) + 1, y, item[2], C.na, C.bg)
    column = column + M.length(item[1]) + 1 + M.length(item[2]) + 3
  end
end

---Lines of a log, newest first, in a card with a scroll mark on the right edge
---@param lines string[] Coded log lines
---@param offset integer First line shown, 0 = newest
---@return integer offset Kept inside the list
function M.log(cv, x, y, w, h, title, lines, offset)
  local size = h - 2
  local maxOffset = math.max(0, #lines - size)
  offset = math.max(0, math.min(offset or 0, maxOffset))

  M.card(cv, x, y, w, h, title, {right = #lines > 0 and (#lines.." events") or nil, rightColor = M.colors.na})

  for i = 1, size do
    if lines[i + offset] ~= nil then
      cv:putCoded(x + 2, y + i, lines[i + offset], w - 4, M.colors.card)
    end
  end

  if maxOffset > 0 and size > 1 then
    local position = math.floor(offset / maxOffset * (size - 1) + 0.5)
    cv:put(x + w - 1, y + 1 + position, CH.mark, M.colors.red, M.colors.card)
  end

  return offset
end

return M
