-- Several screens from one computer. Each screen gets frames of coded lines (&0xRRGGBB; foreground,
-- &&0xRRGGBB; background, as neon-ui canvas:lines() gives them); only changed rows are drawn. With a GPU
-- per screen each keeps its screen; otherwise one GPU is moved between screens (slower, but works)
local M = {}

local screens = {}   -- address -> {width, height, shown, gpu}

function M.setup(settings)
  M.settings = settings
  screens = {}
end

---Addresses of all screens, sorted (a stable order to name them by)
function M.list()
  local component = require("component")
  local list = {}

  for address in component.list("screen") do
    list[#list + 1] = address
  end

  table.sort(list)
  return list
end

local function gpus()
  local component = require("component")
  local list = {}

  for address in component.list("gpu") do
    list[#list + 1] = address
  end

  table.sort(list)
  return list
end

---Get a screen ready: its resolution from its shape for a number of rows. Returns width, height
---@param address string Screen address (or its start)
---@param rows integer|nil
function M.open(address, rows)
  local component = require("component")
  local full = component.get(address, "screen")
  assert(full ~= nil, "[multi-screen] no screen "..tostring(address))

  -- a GPU of its own when there are enough, else the first one
  local used, gpuAddress = {}, nil

  for _, entry in pairs(screens) do
    used[entry.gpu] = true
  end

  for _, candidate in ipairs(gpus()) do
    if not used[candidate] then
      gpuAddress = candidate
      break
    end
  end

  gpuAddress = gpuAddress or gpus()[1]
  assert(gpuAddress ~= nil, "[multi-screen] no GPU")

  local card = component.proxy(gpuAddress)
  card.bind(full, false)
  local maxWidth, maxHeight = card.maxResolution()
  local height = math.min(rows or M.settings.rows, maxHeight)
  local width = math.min(80, maxWidth)
  local isOk, a, b = pcall(function () return component.proxy(full).getAspectRatio() end)

  if isOk and type(a) == "number" and type(b) == "number" and b > 0 then
    width = math.min(math.max(width, math.floor(height * 2 * a / b + 0.5)), maxWidth)
  end

  card.setResolution(width, height)
  screens[full] = {width = width, height = height, shown = nil, gpu = gpuAddress}
  return width, height
end

---Size of an opened screen
function M.size(address)
  local entry = screens[require("component").get(address, "screen") or address]
  assert(entry ~= nil, "[multi-screen] open the screen first")
  return entry.width, entry.height
end

local function drawLine(card, line, y)
  local foreground, background = 0xFFFFFF, 0x000000
  local x, i, run = 1, 1, {}
  card.setForeground(foreground)
  card.setBackground(background)

  local function flush()
    if #run > 0 then
      card.set(x, y, table.concat(run))
      x = x + #run
      run = {}
    end
  end

  while i <= #line do
    local code = line:match("^&&?(0x%x+);", i)

    if code ~= nil then
      local isBackground = line:sub(i + 1, i + 1) == "&"
      local color = tonumber(code)
      flush()

      if isBackground then
        background = color
        card.setBackground(color)
      else
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

---Show a frame on a screen. Returns the number of rows drawn
function M.show(address, lines)
  local component = require("component")
  local full = component.get(address, "screen") or address
  local entry = screens[full]
  assert(entry ~= nil, "[multi-screen] open the screen first")

  local changed = {}

  for y = 1, entry.height do
    if entry.shown == nil or entry.shown[y] ~= lines[y] then
      changed[#changed + 1] = y
    end
  end

  if #changed == 0 then
    return 0
  end

  local card = component.proxy(entry.gpu)

  if card.getScreen() ~= full then
    card.bind(full, false)
    card.setResolution(entry.width, entry.height)
  end

  for _, y in ipairs(changed) do
    drawLine(card, lines[y] or "", y)
  end

  -- a copy: the program may change its table for the next frame
  entry.shown = {}

  for y = 1, entry.height do
    entry.shown[y] = lines[y]
  end

  return #changed
end

---Draw everything again next time (all screens, or one)
function M.redraw(address)
  for key, entry in pairs(screens) do
    if address == nil or key == address then
      entry.shown = nil
    end
  end
end

---Clear the opened screens and forget them
function M.close()
  local component = require("component")

  for full, entry in pairs(screens) do
    pcall(function ()
      local card = component.proxy(entry.gpu)
      card.bind(full, false)
      local w, h = card.maxResolution()
      card.setResolution(w, h)
      card.setForeground(0xFFFFFF)
      card.setBackground(0x000000)
      card.fill(1, 1, w, h, " ")
    end)
  end

  screens = {}
end

return M
