-- Real time with a time zone. OpenComputers has no real clock: os.time() is game time and
-- computer.uptime() counts world ticks (it slows down with lag). Writing a file and reading its
-- modification time gives the real time; in between it counts on from the uptime
local M = {}

local clock = nil      -- real time in seconds (UTC) when it was last read
local readAt = nil     -- uptime at that moment

function M.setup(settings)
  M.settings = settings
  clock, readAt = nil, nil
end

local function read()
  local filesystem = require("filesystem")
  local path = M.settings.tmpFile
  local file = io.open(path, "w")

  if file == nil then
    error("[clock] can't write "..path)
  end

  file:write("")
  file:close()

  return math.floor(filesystem.lastModified(path) / 1000)
end

---Real time in seconds since 1970, in the time zone of the settings
---@return integer
function M.now()
  local now = require("computer").uptime()

  if readAt == nil or now - readAt >= M.settings.readSeconds or now < readAt then
    clock = read()
    readAt = now
  end

  return clock + math.floor(now - readAt) + math.floor(M.settings.timeZone * 3600)
end

---Format a time like os.date, default now: "%H:%M:%S", "%d.%m.%Y %H:%M"
---@param format? string
---@param time? integer From now()
---@return string
function M.format(format, time)
  return tostring(os.date(format or "%d.%m.%Y %H:%M:%S", time or M.now()))
end

---Seconds between two times from now()
function M.since(time)
  return M.now() - time
end

return M
