-- Log for the screen (coloured lines, newest first, repeats folded into "(x4)") and for a file
-- (full date, rotated when it grows). Programs log with log.info(...) or event.push("log_info", ...)
local M = {}

local levels = {debug = 0, info = 1, warning = 2, error = 3}
local lines = {}
local lastKey, repeats = nil, 0
local listenerIds = {}

function M.setup(settings)
  M.settings = settings
end

---The clock addon, set up once with its settings if the program did not load it itself
local function clock()
  local module = require("addons.clock")

  if module.settings == nil then
    require("addons.core").load("clock")
  end

  return module
end

local function text(...)
  local parts = {}

  for i = 1, select("#", ...) do
    parts[#parts + 1] = tostring((select(i, ...)))
  end

  return table.concat(parts)
end

local function toScreen(level, message)
  if levels[level] < levels[M.settings.screenLevel] then
    return
  end

  local color = ({debug = "&lightGray;", info = "&white;", warning = "&yellow;", error = "&red;[Error] "})[level]

  if level == "info" then
    for tag, tagColor in pairs(M.settings.tagColors or {}) do
      if message:sub(1, #tag) == tag then
        color = "&"..tagColor..";"
      end
    end
  end

  local line = "&lightGray;"..clock().format(M.settings.screenTime).." "..color..message

  -- The same message again replaces the newest line with a count, so repeats don't push the rest away
  local key = level..":"..message

  if key == lastKey and #lines > 0 then
    repeats = repeats + 1
    lines[1] = line.." (x"..repeats..")"
    return
  end

  lastKey, repeats = key, 1
  table.insert(lines, 1, line)

  while #lines > M.settings.screenLines do
    table.remove(lines)
  end
end

local function toFile(level, message)
  local path = M.settings.filePath

  if path == nil or path == "" or levels[level] < levels[M.settings.fileLevel] then
    return
  end

  -- Keep the file small: OC disks are tiny. The full file becomes <path>.old
  local filesystem = require("filesystem")

  if filesystem.size(path) > M.settings.fileMaxKb * 1024 then
    filesystem.remove(path..".old")
    filesystem.rename(path, path..".old")
  end

  local file = io.open(path, "a")

  if file ~= nil then
    file:write(clock().format(M.settings.fileTime), " [", level, "] ", message, "\n")
    file:close()
  end
end

---Log a message at a level: "debug", "info", "warning" or "error". Parts are joined
function M.log(level, ...)
  if levels[level] == nil then
    error("[event-log] unknown level "..tostring(level))
  end

  local message = text(...)
  toScreen(level, message)
  toFile(level, message)
end

function M.debug(...) M.log("debug", ...) end
function M.info(...) M.log("info", ...) end
function M.warning(...) M.log("warning", ...) end
function M.error(...) M.log("error", ...) end

---Lines for the screen, newest first, with colour names (&white; ...) for neon-ui's canvas:putCoded
---@return string[]
function M.lines()
  return lines
end

function M.clear()
  lines = {}
  lastKey, repeats = nil, 0
end

---Also log what is pushed as events: event.push("log_info", "text")
function M.start()
  local event = require("event")

  for level in pairs(levels) do
    table.insert(listenerIds, event.listen("log_"..level, function (_, ...)
      M.log(level, ...)
    end))
  end
end

function M.stop()
  local event = require("event")

  for _, id in ipairs(listenerIds) do
    event.cancel(id)
  end

  listenerIds = {}
end

return M
