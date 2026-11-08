local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

local addons = require("addons.core")
local recovery = addons.load("recovery", {retrySeconds = 30, giveUpMinutes = 5, healthySeconds = 60})
local event = require("event")

t.test("a start that fails once is retried after 30 s, then runs until quit", function ()
  local starts, steps, stops, waits = 0, 0, {}, 0
  local began = oc.now()
  local result = recovery.run({
    start = function () starts = starts + 1 if starts == 1 then error("adapter missing") end end,
    step = function () steps = steps + 1 os.sleep(1) return steps < 3 end,
    stop = function (reason) stops[#stops + 1] = reason end,
    waiting = function () waits = waits + 1 end,
  })
  t.equal(result, "quit")
  t.equal(starts, 2)
  t.equal(waits, 30, "a countdown second by second")
  t.contains(stops[1], "adapter missing")
  t.equal(stops[2], "quit")
  t.truthy(oc.now() - began >= 30, "waited")
end)

t.test("an error in a listener stops the run, and its listeners are cancelled", function ()
  local starts, before = 0, oc.leftovers()
  local result = recovery.run({
    start = function ()
      starts = starts + 1
      recovery.listen("boom", function () error("listener broke") end)
      recovery.timer(1, function () end, math.huge)
    end,
    step = function ()
      if starts == 1 then event.push("boom") end
      os.sleep(1)
      return starts < 2
    end,
    stop = function () end,
  })
  t.equal(result, "quit")
  t.equal(starts, 2, "started again after the listener error")
  t.equal(oc.leftovers(), before, "no listeners or timers left")
end)

t.test("callbacks of an old run do nothing", function ()
  local late = nil
  local calls = 0
  recovery.run({
    start = function ()
      calls = calls + 1
      if calls == 1 then
        late = recovery.guard(function () error("old run") end)
        error("first run fails")
      end
    end,
    step = function () late() os.sleep(1) return false end,
    stop = function () end,
  })
  t.equal(calls, 2, "the late callback did not stop the second run")
end)

t.test("failing for 5 minutes: safe state and give up", function ()
  local safe = nil
  local result, problem = recovery.run({
    start = function () error("plant not found") end,
    step = function () return true end,
    stop = function () end,
    safe = function (p) safe = p end,
  })
  t.equal(result, "gave up")
  t.contains(problem, "plant not found")
  t.contains(safe, "plant not found")
end)

t.test("a run that worked for a while starts a fresh count", function ()
  local runs = 0
  local result = recovery.run({
    start = function () runs = runs + 1 end,
    step = function ()
      os.sleep(120)                     -- every run works for 2 minutes, then fails
      if runs < 6 then error("rare hiccup") end
      return false
    end,
    stop = function () end,
    safe = function () end,
  })
  t.equal(result, "quit", "never gave up: each failure came after a healthy run")
  t.equal(runs, 6)
end)

t.test("step can ask for a restart: no pause, no error", function ()
  local starts, stops = 0, {}
  local began = oc.now()
  local result = recovery.run({
    start = function () starts = starts + 1 end,
    step = function () if starts == 1 then return "restart" end return false end,
    stop = function (reason) stops[#stops + 1] = reason end,
  })
  t.equal(result, "quit")
  t.equal(starts, 2)
  t.equal(stops[1], "restart")
  t.equal(oc.now() - began, 0, "no pause")
end)

t.test("waiting gets every line of the error, without the stack traceback", function ()
  local seen = nil
  recovery.run({
    start = function () error("config.lua has mistakes:\n  mode: is \"fast\"", 0) end,
    step = function () return true end,
    stop = function () end,
    safe = function () end,
    waiting = function (problem) seen = problem return "quit" end,
  })
  t.equal(seen, 'config.lua has mistakes:\n  mode: is "fast"')
end)

t.test("waiting can quit before the restart", function ()
  local result = recovery.run({
    start = function () error("x") end,
    step = function () return true end,
    stop = function () end,
    safe = function () end,
    waiting = function (_, left) if left == 25 then return "quit" end end,
  })
  t.equal(result, "quit")
end)

return t.finish()
