-- Finished crafting jobs: while started it records every "ae2_job_done" from cpu-monitor (also jobs of
-- other programs and players), keeps the newest in memory and writes them to a file, one per line:
-- time<TAB>cpu<TAB>size<TAB>seconds<TAB>label
local M = {}

local listener, jobs = nil, {}

function M.setup(settings)
  M.settings = settings
  jobs = {}
end

local function clock()
  return require("addons.core").load("clock")
end

local function trim()
  while #jobs > M.settings.keep do
    table.remove(jobs, 1)
  end
end

local function write(job)
  local path = M.settings.filePath

  if path == nil or path == "" then
    return
  end

  local filesystem = require("filesystem")

  if filesystem.exists(path) and filesystem.size(path) > M.settings.fileMaxKb * 1024 then
    filesystem.remove(path..".old")
    filesystem.rename(path, path..".old")
  end

  local file = io.open(path, "a")

  if file ~= nil then
    file:write(job.time, "\t", job.cpu, "\t", job.size, "\t", math.floor(job.seconds), "\t", job.label, "\n")
    file:close()
  end
end

---Record a job {cpu, label, size, seconds}; time is now unless given
---@param job table
function M.add(job)
  job = {time = job.time or clock().now(), cpu = tostring(job.cpu or "?"), label = tostring(job.label or "?"),
    size = tonumber(job.size) or 0, seconds = tonumber(job.seconds) or 0}
  jobs[#jobs + 1] = job
  trim()
  write(job)
end

---Read the jobs kept in the file (newest settings.keep), e.g. after a restart
function M.load()
  jobs = {}
  local path = M.settings.filePath
  local file = path ~= nil and path ~= "" and io.open(path, "r") or nil

  if file == nil then
    return
  end

  for line in file:lines() do
    local time, cpu, size, seconds, label = line:match("^(%d+)\t([^\t]*)\t(%d+)\t(%d+)\t(.*)$")

    if time ~= nil then
      jobs[#jobs + 1] = {time = tonumber(time), cpu = cpu, size = tonumber(size), seconds = tonumber(seconds), label = label}
      trim()
    end
  end

  file:close()
end

---The newest jobs, newest first
---@param n number|nil default 10
---@return table[]
function M.recent(n)
  local list = {}

  for i = #jobs, math.max(1, #jobs - (n or 10) + 1), -1 do
    list[#list + 1] = jobs[i]
  end

  return list
end

---Totals per item, most crafted first: {label, jobs, items, seconds}
---@return table[]
function M.stats()
  local byLabel, list = {}, {}

  for _, job in ipairs(jobs) do
    local row = byLabel[job.label]

    if row == nil then
      row = {label = job.label, jobs = 0, items = 0, seconds = 0}
      byLabel[job.label] = row
      list[#list + 1] = row
    end

    row.jobs, row.items, row.seconds = row.jobs + 1, row.items + job.size, row.seconds + job.seconds
  end

  table.sort(list, function (a, b) return a.items > b.items end)
  return list
end

function M.clear()
  jobs = {}
end

---Load the file and record every finished job until stop()
function M.start()
  local event = require("event")
  M.stop()
  M.load()

  listener = event.listen("ae2_job_done", function (_, cpu, label, size, seconds)
    local isOk, problem = pcall(M.add, {cpu = cpu, label = label, size = size, seconds = seconds})

    if not isOk then
      event.push("log_error", "[Crafts] "..tostring(problem))
    end
  end)
end

function M.stop()
  if listener ~= nil then
    require("event").cancel(listener)
    listener = nil
  end
end

return M
