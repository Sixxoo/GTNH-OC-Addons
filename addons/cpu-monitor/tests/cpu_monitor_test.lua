local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

local event = require("event")
local addons = require("addons.core")
local _, net = oc.meNetwork({cpus = {{name = "Main"}, {name = "Big", storage = 1048576, coprocessors = 4}}})
local cpus = addons.load("cpu-monitor", {intervalSeconds = 5})
local me = addons.load("ae2").find()

local logs, done = {}, {}
event.listen("log_info", function (_, text) logs[#logs + 1] = text end)
event.listen("ae2_job_done", function (_, cpu, label, size, seconds) done[#done + 1] = {cpu, label, size, seconds} end)

local base = oc.leftovers()

t.test("all free", function ()
  local result = cpus.read(me)
  t.equal(result.total, 2) t.equal(result.free, 2) t.equal(result.busy, 0)
  t.equal(result.cpus[2].coprocessors, 4)
end)

t.test("a job is followed from start to end", function ()
  cpus.start(me)
  net.cpus[1].busy, net.cpus[1].output = true, {label = "Iron Ingot", size = 64}
  oc.advance(5)
  local result = cpus.last()
  t.equal(result.busy, 1) t.equal(result.cpus[1].label, "Iron Ingot") t.equal(result.cpus[1].size, 64)
  t.contains(logs[#logs], "Main: crafting 64x Iron Ingot")
  oc.advance(120)
  t.equal(cpus.last().cpus[1].seconds, 120)
  net.cpus[1].busy = false
  oc.advance(5)
  t.equal(#done, 1) t.equal(done[1][1], "Main") t.equal(done[1][3], 64) t.equal(done[1][4], 125)
  t.contains(logs[#logs], "done in 2m 05s")
  cpus.stop()
  t.equal(oc.leftovers(), base)
end)

t.test("a new job on a busy CPU ends the old one", function ()
  net.cpus[2].busy, net.cpus[2].output = true, {label = "Gear", size = 4}
  cpus.read(me)
  net.cpus[2].output = {label = "Plate", size = 8}
  cpus.read(me)
  t.equal(done[#done][2], "Gear")
end)

return t.finish()
