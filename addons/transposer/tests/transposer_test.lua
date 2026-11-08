local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

local addons = require("addons.core")
local tp = addons.load("transposer")
local component = require("component")

-- Like Sixxo's T3: Polyaluminium Chloride above, the input hatch below, nothing on the sides
local address, moves = oc.transposer({
  [0] = {{capacity = 1000000}},
  [1] = {{name = "polyaluminiumchloride", amount = 4000000}},
  [2] = {},
}, {
  [3] = {{label = "Sodium Hydroxide Dust", size = 64, slot = 5}},
})
local proxy = component.proxy(address)

t.test("finds a fluid on any side except the hatch's", function ()
  local found, missing = tp.findFluids(proxy, {"polyaluminiumchloride"}, {"down"})
  t.equal(#missing, 0)
  t.equal(found.polyaluminiumchloride.side, 1)
  t.equal(found.polyaluminiumchloride.amount, 4000000)
end)

t.test("the hatch side is skipped: with the hatch up, the fluid up is not a source", function ()
  local _, missing = tp.findFluids(proxy, {"polyaluminiumchloride"}, {"up"})
  t.equal(missing[1], "polyaluminiumchloride")
end)

t.test("sides without tanks and empty tanks don't break the search", function ()
  local tanks = tp.tanks(proxy)
  t.equal(#tanks, 2)
  t.equal(tanks[1].name, nil, "empty hatch")
  t.equal(tanks[1].amount, 0)
end)

t.test("describe says what is on each side", function ()
  local lines = tp.describe(proxy)
  t.equal(lines[1], "down: empty tank")
  t.equal(lines[2], "up: polyaluminiumchloride 4000000")
  t.equal(lines[3], "north: no tank")
  t.equal(lines[4], "south: nothing")
end)

t.test("fill moves the amount down into the hatch", function ()
  local found = tp.findFluids(proxy, {"polyaluminiumchloride"}, {"down"})
  t.equal(tp.fill(proxy, found.polyaluminiumchloride, "down", 900000), 900000)
  t.equal(moves[1].to, 0)
  t.equal(proxy.getFluidInTank(0, 1).amount, 900000, "in the hatch")
end)

t.test("fill stops when nothing more moves", function ()
  local found = tp.findFluids(proxy, {"polyaluminiumchloride"}, {"down"})
  t.equal(tp.fill(proxy, found.polyaluminiumchloride, "down", 9999999), 3100000, "only what was left")
end)

t.test("finds items by label and moves them", function ()
  local found, missing = tp.findItems(proxy, {"Sodium Hydroxide Dust", "Unobtainium"}, {"down"})
  t.equal(found["Sodium Hydroxide Dust"].slot, 5)
  t.equal(missing[1], "Unobtainium")
  t.equal(tp.moveItems(proxy, found["Sodium Hydroxide Dust"], "down", 10), 10)
end)

t.test("sides by name or number", function ()
  t.equal(tp.side("Down"), 0) t.equal(tp.side(5), 5) t.equal(tp.side("x"), nil)
  t.equal(tp.sideName(1), "up")
end)

return t.finish()
