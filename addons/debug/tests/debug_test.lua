local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

local event = require("event")
local addons = require("addons.core")
local dbg = addons.load("debug", {depth = 3})

t.test("dump: sorted, nested, cycles", function ()
  local value = {b = 2, a = {1, "x"}}
  value.self = value
  local text = dbg.dump(value)
  t.contains(text, 'a = {') t.contains(text, '"x"') t.contains(text, "self = <cycle>")
  t.truthy(text:find("a =") < text:find("b ="))
end)

t.test("components, memory, trace", function ()
  oc.gtMachine("multimachine.test")
  t.equal(dbg.components()[1].type, "gt_machine")
  t.equal(dbg.memory().percent, 50)
  local logged
  event.listen("log_error", function (_, text) logged = text end)
  local ok, problem = dbg.trace(function () error("boom") end)
  t.falsy(ok) t.contains(problem, "boom") t.contains(logged, "stack traceback")
  t.equal(select(2, dbg.trace(function (a) return a * 2 end, 21)), 42)
end)

t.test("record signals for a while", function ()
  event.timer(1, function () event.push("custom_thing", 1) end)
  local list = dbg.record(3, "^custom")
  t.equal(#list, 1) t.equal(list[1][1], "custom_thing")
end)

return t.finish()
