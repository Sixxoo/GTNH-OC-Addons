-- Crafting CPUs: which are busy, what they craft and for how long. While started it follows them and
-- pushes "ae2_job_started" (cpu, label, size) and "ae2_job_done" (cpu, label, size, seconds), which
-- craft-history records; with logJobs it also logs them through the event-log signals
local M = {}

local timer, jobs, last = nil, {}, nil

function M.setup(settings)
  M.settings = settings
  jobs, last = {}, nil
end

local function ae2()
  return require("addons.core").load("ae2")
end

local function now()
  return require("computer").uptime()
end

local function duration(seconds)
  seconds = math.floor(seconds)

  if seconds >= 3600 then
    return string.format("%dh %02dm", seconds // 3600, seconds % 3600 // 60)
  elseif seconds >= 60 then
    return string.format("%dm %02ds", seconds // 60, seconds % 60)
  end

  return seconds.."s"
end

---Look at the CPUs once and follow their jobs. {cpus = {{name, busy, storage, coprocessors, label,
---size, seconds}}, busy, free, total}
---@param proxy table
---@return table
function M.read(proxy)
  local event = require("event")
  local result = {cpus = {}, busy = 0, free = 0, total = 0}
  local seen = {}

  for _, cpu in ipairs(ae2().cpus(proxy)) do
    local row = {name = cpu.name, busy = cpu.busy, storage = cpu.storage, coprocessors = cpu.coprocessors}
    seen[cpu.name] = true

    if cpu.busy then
      local output

      if cpu.cpu ~= nil and cpu.cpu.finalOutput ~= nil then
        local isOk, value = pcall(cpu.cpu.finalOutput)
        output = isOk and type(value) == "table" and value or nil
      end

      row.label = output and (output.label or output.name) or "?"
      row.size = output and (output.size or output.amount) or 0

      local job = jobs[cpu.name]

      if job == nil or job.label ~= row.label then
        if job ~= nil then
          M.finished(cpu.name, job)
        end

        job = {label = row.label, size = row.size, since = now()}
        jobs[cpu.name] = job

        if M.settings.logJobs then
          event.push("log_info", "[CPU] "..cpu.name..": crafting "..row.size.."x "..row.label)
        end

        event.push("ae2_job_started", cpu.name, row.label, row.size)
      end

      row.seconds = now() - job.since
      result.busy = result.busy + 1
    else
      if jobs[cpu.name] ~= nil then
        M.finished(cpu.name, jobs[cpu.name])
        jobs[cpu.name] = nil
      end

      result.free = result.free + 1
    end

    result.cpus[#result.cpus + 1] = row
  end

  for name, job in pairs(jobs) do
    if not seen[name] then
      M.finished(name, job)
      jobs[name] = nil
    end
  end

  result.total = #result.cpus
  last = result
  return result
end

---A job ended (called by read)
function M.finished(cpu, job)
  local event = require("event")
  local seconds = now() - job.since

  if M.settings.logJobs then
    event.push("log_info", "[CPU] "..cpu..": "..job.size.."x "..job.label.." done in "..duration(seconds))
  end

  event.push("ae2_job_done", cpu, job.label, job.size, seconds)
end

---The last read, or nil
function M.last()
  return last
end

M.duration = duration

---Follow the CPUs every intervalSeconds until stop()
---@param proxy table
function M.start(proxy)
  local event = require("event")
  M.stop()

  timer = event.timer(M.settings.intervalSeconds, function ()
    local isOk, problem = pcall(M.read, proxy)

    if not isOk then
      event.push("log_error", "[CPU] "..tostring(problem))
    end
  end, math.huge)

  pcall(M.read, proxy)
end

function M.stop()
  if timer ~= nil then
    require("event").cancel(timer)
    timer = nil
  end
end

return M
