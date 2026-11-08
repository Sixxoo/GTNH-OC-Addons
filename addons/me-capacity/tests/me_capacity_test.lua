local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

local event = require("event")
local addons = require("addons.core")

local function cell(slot, used, total, label)
  return {slot = slot, name = "appliedenergistics2:item.ItemBasicStorageCell.64k", label = label or "64k ME Storage Cell",
    size = 1, totalBytes = total or 65536, usedBytes = used, storedItemTypes = 10, getTotalItemTypes = 63}
end

local drive1 = {[2] = {cell(1, 32768), cell(2, 65536)}}
local drive2 = {[5] = {cell(1, 0, 262144, "256k"), {slot = 2, name = "ae2fc:fluid_storage64", label = "64k Fluid Cell", size = 1}}}
local t1 = oc.transposer({}, drive1)
oc.transposer({}, drive2)
oc.transposer({}, {[3] = {{slot = 1, name = "minecraft:cobblestone", label = "Cobblestone", size = 64}}})

local capacity = addons.load("me-capacity", {warnPercent = 50})
local logs = {}
event.listen("log_warning", function (_, text) logs[#logs + 1] = "W "..text end)
event.listen("log_info", function (_, text) logs[#logs + 1] = "I "..text end)

t.test("finds every drive, adds up bytes, counts fluid cells as unknown", function ()
  local result = capacity.read()
  t.equal(#result.drives, 2)
  t.equal(result.cells, 3) t.equal(result.unknown, 1)
  t.equal(result.totalBytes, 65536 * 2 + 262144)
  t.equal(result.usedBytes, 32768 + 65536)
  t.equal(result.freeBytes, result.totalBytes - result.usedBytes)
  t.equal(result.totalTypes, 189)
end)

t.test("only the configured drives", function ()
  local only = addons.load("me-capacity", {drives = {{transposer = t1:sub(1, 6), side = "north"}}})
  local result = only.read()
  t.equal(#result.drives, 1) t.equal(result.fraction, 0.75)
  local _, problem = addons.load("me-capacity", {drives = {{transposer = "ffff", side = "north"}}}).read()
  t.contains(problem, "no transposer")
end)

t.test("warns once when full, and when there is room again", function ()
  capacity = addons.load("me-capacity", {drives = {{transposer = t1, side = 2}}, warnPercent = 50})
  capacity.check() capacity.check()
  t.equal(#logs, 1) t.contains(logs[1], "W [ME] Storage cells are 75% full")
  drive1[2][2].usedBytes = 0
  capacity.check()
  t.contains(logs[2], "I [ME] Storage cells have room again (25%)")
end)

return t.finish()
