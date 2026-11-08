local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

local addons = require("addons.core")
local ae2 = addons.load("ae2")

local address, net = oc.meNetwork({
  items = {
    {name = "minecraft:iron_ingot", damage = 0, label = "Iron Ingot", size = 1200, craftable = true},
    {name = "gregtech:gt.blockores", damage = 86, label = "Gold Ore", size = 64},
    {name = "gregtech:gt.blockores", damage = 32, label = "Iron Ore", size = 10},
  },
  fluids = {{name = "water", label = "Water", amount = 5000}},
  cpus = {{name = "Main", busy = true, output = {label = "Iron Ingot", size = 64}}, {name = ""}},
  power = {stored = 500, max = 1000, usage = 12.5},
})

t.test("find: the first one, by address start, or why not", function ()
  t.equal(ae2.find().address, address)
  t.equal(ae2.find(address:sub(1, 6)).address, address)
  local proxy, problem = ae2.find("ffff")
  t.equal(proxy, nil) t.contains(problem, "components me_interface")
end)

t.test("keys: fluid, item, item with damage", function ()
  t.equal(ae2.spec("fluid:water").fluid, true)
  local ore = ae2.spec("gregtech:gt.blockores:86")
  t.equal(ore.name, "gregtech:gt.blockores") t.equal(ore.damage, 86)
  t.equal(ae2.spec("minecraft:iron_ingot").damage, nil)
  t.equal(ae2.key({name = "water", amount = 5}), "fluid:water")
  t.equal(ae2.key({name = "gregtech:gt.blockores", damage = 86, size = 1}), "gregtech:gt.blockores:86")
end)

t.test("stock of fluids and items, 0 when missing", function ()
  local me = ae2.find()
  t.equal(ae2.stock(me, "fluid:water"), 5000)
  t.equal(ae2.stock(me, "gregtech:gt.blockores:86"), 64)
  t.equal(ae2.stock(me, "gregtech:gt.blockores"), 74)
  t.equal(ae2.stock(me, {label = "Iron Ingot"}), 1200)
  t.equal(ae2.stock(me, "fluid:lava"), 0)
end)

t.test("craftables are cached, also 'not craftable'", function ()
  local me = ae2.find()
  t.truthy(ae2.craftable(me, "minecraft:iron_ingot"))
  t.falsy(ae2.craftable(me, "gregtech:gt.blockores:86"))
  local before = net.calls.getCraftables
  ae2.craftable(me, "minecraft:iron_ingot") ae2.craftable(me, "gregtech:gt.blockores:86")
  t.equal(net.calls.getCraftables, before)
  oc.advance(601)
  ae2.craftable(me, "minecraft:iron_ingot")
  t.equal(net.calls.getCraftables, before + 1)
end)

t.test("request and follow a job", function ()
  local me = ae2.find()
  local job = assert(ae2.request(me, "minecraft:iron_ingot", 64, "Main"))
  t.equal(net.jobs[1].amount, 64) t.equal(net.jobs[1].cpu, "Main")
  t.equal(ae2.jobState(job), "computing")
  net.jobs[1].state = "running" t.equal(ae2.jobState(job), "running")
  net.jobs[1].state = "failed" net.jobs[1].why = "missing resources"
  local state, why = ae2.jobState(job)
  t.equal(state, "failed") t.equal(why, "missing resources")
  local none, problem = ae2.request(me, "gregtech:gt.blockores:86", 1)
  t.equal(none, nil) t.contains(problem, "no pattern")
end)

t.test("power and CPUs", function ()
  local me = ae2.find()
  local power = ae2.power(me)
  t.equal(power.fraction, 0.5) t.equal(power.usage, 12.5)
  local cpus = ae2.cpus(me)
  t.equal(#cpus, 2) t.equal(cpus[1].busy, true) t.equal(cpus[2].name, "CPU 2")
end)

return t.finish()
