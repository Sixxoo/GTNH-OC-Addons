local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

local addons = require("addons.core")
local profiler = addons.load("profiler")

t.test("measure and wrap count calls and pass results through", function ()
  t.equal(profiler.measure("add", function (a, b) return a + b end, 2, 3), 5)
  local slow = profiler.wrap("loop", function () local s = 0 for i = 1, 20000 do s = s + i end return s end)
  slow() slow()
  local report = profiler.report("calls")
  t.equal(report[1].name, "loop") t.equal(report[1].calls, 2)
  t.errors(function () profiler.measure("bad", function () error("x") end) end)
  t.equal(#profiler.report(), 3)
end)

t.test("a component proxy counts every method", function ()
  local address = oc.gtMachine("multimachine.test", {work = true})
  local plant = profiler.proxy(require("component").proxy(address), "plant")
  plant.hasWork() plant.hasWork() plant.isWorkAllowed()
  local byName = {}
  for _, row in ipairs(profiler.report()) do byName[row.name] = row end
  t.equal(byName["plant.hasWork"].calls, 2) t.equal(byName["plant.isWorkAllowed"].calls, 1)
  t.contains(profiler.lines(2)[1], "CALLS")
  profiler.reset()
  t.equal(#profiler.report(), 0)
end)

return t.finish()
