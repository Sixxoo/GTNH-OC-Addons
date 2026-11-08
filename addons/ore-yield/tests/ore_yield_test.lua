local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

local addons = require("addons.core")
local _, net = oc.meNetwork({items = {
  {name = "gregtech:gt.blockores", damage = 86, label = "Gold Ore", size = 100},
  {name = "gregtech:gt.blockores", damage = 32, label = "Iron Ore", size = 1000},
  {name = "minecraft:cobblestone", damage = 0, label = "Cobblestone", size = 5},
}})
local yield = addons.load("ore-yield", {intervalSeconds = 60, windowMinutes = 30})
local me = addons.load("ae2").find()

local base = oc.leftovers()

t.test("no rate from one sample", function ()
  yield.sample(me, 0)
  t.equal(yield.rates().minutes, 0)
end)

t.test("per hour, fastest first, only the filtered items", function ()
  net.items[1].size = 150    -- +50 in 10 minutes = 300/h
  net.items[2].size = 1100   -- +100 = 600/h
  net.items[3].size = 500
  yield.sample(me, 600)
  local rates = yield.rates()
  t.equal(rates.minutes, 10)
  t.equal(#rates.rows, 2)
  t.equal(rates.rows[1].label, "Iron Ore") t.equal(rates.rows[1].perHour, 600)
  t.equal(rates.rows[2].perHour, 300)
  t.equal(rates.perHour, 900)
end)

t.test("the window drops old samples", function ()
  yield.clear()
  for minute = 0, 60, 10 do
    net.items[1].size = 100 + minute * 10
    yield.sample(me, minute * 60)
  end
  local rates = yield.rates()
  t.equal(rates.minutes, 30)
  t.equal(rates.rows[1].perHour, 600)
end)

t.test("start samples by itself, stop cleans up", function ()
  yield.clear()
  yield.start(me)
  oc.advance(120)
  t.truthy(yield.rates().minutes > 0)
  yield.stop()
  t.equal(oc.leftovers(), base)
end)

return t.finish()
