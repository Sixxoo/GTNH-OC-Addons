-- Keeps a program running through errors: a failing run is stopped and cleaned up, then started again
-- after a pause; if it keeps failing for minutes, the program goes to a safe state and stops.
-- Errors inside listeners and timers are caught too (OpenOS only writes them to /tmp/event.log).
local M = {}

local run = 0             -- number of the current run; callbacks of older runs are ignored
local problem = nil       -- first error of the current run
local ids = {}            -- listeners and timers of the current run

function M.setup(settings)
  M.settings = settings
end

local function traceback(err)
  return debug.traceback(tostring(err), 2)
end

local function firstLine(text)
  return (tostring(text):match("^[^\n]*"))
end

---Report an error of the current run from anywhere: the run stops and starts again
function M.fail(message)
  if problem == nil then
    problem = tostring(message)
  end
end

---Wrap a callback so its errors stop the run instead of vanishing. Old runs' callbacks do nothing
function M.guard(callback)
  local mine = run

  return function (...)
    if mine ~= run then
      return
    end

    local result = table.pack(xpcall(callback, traceback, ...))

    if not result[1] then
      M.fail(result[2])
      return
    end

    return table.unpack(result, 2, result.n)
  end
end

---event.listen for this run: guarded, cancelled when the run ends
function M.listen(name, callback)
  local id = require("event").listen(name, M.guard(callback))
  ids[#ids + 1] = id
  return id
end

---event.timer for this run: guarded, cancelled when the run ends
function M.timer(interval, callback, times)
  local id = require("event").timer(interval, M.guard(callback), times)
  ids[#ids + 1] = id
  return id
end

local function cleanUp()
  local event = require("event")

  for _, id in ipairs(ids) do
    event.cancel(id)
  end

  ids = {}
end

---Run a program with recovery
---@param handlers table
---  start(runNumber)  set up the run; listeners and timers through recovery.listen / recovery.timer
---  step(runNumber)   one pass of the main loop; return false to quit
---  stop(reason)      always called when a run ends: "quit", or the error
---  safe(problem)     after giving up: put machines in a safe state
---  waiting(problem, secondsLeft, attempt, giveUpIn)  called every second before a restart; return "quit" to stop
---  started(runNumber, attempt)  optional, after a run started again after an error
---@return string result "quit" or "gave up"
---@return string|nil problem The last error when it gave up
function M.run(handlers)
  local computer = require("computer")
  local failingSince = nil
  local attempt = 0

  while true do
    run = run + 1
    problem = nil
    local mine = run
    local startedAt = computer.uptime()

    local isOk, err = xpcall(handlers.start, traceback, mine)

    if isOk then
      if attempt > 0 and handlers.started then
        handlers.started(mine, attempt)
      end

      while problem == nil do
        local stepOk, result = xpcall(handlers.step, traceback, mine)

        if not stepOk then
          M.fail(result)
        elseif result == false and problem == nil then
          cleanUp()
          run = run + 1
          pcall(handlers.stop, "quit")
          return "quit"
        end
      end
    else
      M.fail(err)
    end

    -- The run failed: clean up, wait, start again; give up after failing for too long
    local failure = problem
    cleanUp()
    run = run + 1
    pcall(handlers.stop, failure)

    local now = computer.uptime()

    if now - startedAt >= M.settings.healthySeconds then
      failingSince, attempt = nil, 0   -- it ran well for a while: a fresh failure
    end

    failingSince = failingSince or startedAt
    attempt = attempt + 1
    local giveUpAt = failingSince + M.settings.giveUpMinutes * 60

    if now >= giveUpAt then
      pcall(handlers.safe, failure)
      return "gave up", failure
    end

    for left = M.settings.retrySeconds, 1, -1 do
      local answer = nil

      if handlers.waiting then
        local waitOk, result = pcall(handlers.waiting, firstLine(failure), left, attempt, math.max(0, giveUpAt - computer.uptime()))
        answer = waitOk and result or nil
      end

      if answer == "quit" then
        pcall(handlers.safe, failure)
        return "quit", failure
      end

      os.sleep(1)
    end
  end
end

---Number of the current run (callbacks can compare it to ignore late work of an old run)
function M.current()
  return run
end

return M
