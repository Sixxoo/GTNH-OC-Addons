local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

local event = require("event")
local addons = require("addons.core")
local _, net = oc.meNetwork({
  items = {{name = "minecraft:iron_ingot", damage = 0, label = "Iron Ingot", size = 50}},
  fluids = {{name = "water", label = "Water", amount = 5000000}},
})
local watch = addons.load("stock-watch", {intervalSeconds = 10, watch = {
  {what = "fluid:water", min = 1000000, max = 32000000},
  {what = "minecraft:iron_ingot", min = 100, label = "Iron"},
}})
local me = addons.load("ae2").find()

local logs, changes = {}, {}
event.listen("log_warning", function (_, text) logs[#logs + 1] = "W "..text end)
event.listen("log_info", function (_, text) logs[#logs + 1] = "I "..text end)
event.listen("stock_changed", function (_, key, state, old) changes[#changes + 1] = key..":"..old..">"..state end)

local base = oc.leftovers()

t.test("state from limits", function ()
  t.equal(watch.state(0, 10), "empty")
  t.equal(watch.state(5, 10), "low")
  t.equal(watch.state(50, 10, 40), "high")
  t.equal(watch.state(20, 10, 40), "ok")
  t.equal(watch.state(0, nil), "ok")
end)

t.test("rows with labels and fractions, no log on the first check", function ()
  local rows = watch.check(me)
  t.equal(rows[1].label, "Water") t.equal(rows[1].state, "ok")
  t.equal(rows[1].fraction, 5000000 / 32000000)
  t.equal(rows[2].label, "Iron") t.equal(rows[2].state, "low")
  t.equal(#logs, 0)
end)

t.test("changes are logged and pushed while started", function ()
  watch.start(me)
  net.fluids[1].amount = 0
  net.items[1].size = 500
  oc.advance(10)
  t.contains(table.concat(logs, "|"), "W [Stock] Water is empty")
  t.contains(table.concat(logs, "|"), "I [Stock] Iron is fine again")
  t.contains(table.concat(changes, "|"), "fluid:water:ok>empty")
  watch.stop()
  t.equal(oc.leftovers(), base)
end)

return t.finish()
