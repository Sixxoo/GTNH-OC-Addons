local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

local filesystem = require("filesystem")
local addons = require("addons.core")
local path = os.tmpname()
filesystem.remove(path)
local history = addons.load("history", {filePath = path, saveSeconds = 300,
  levels = {{seconds = 60, keep = 5}, {seconds = 600, keep = 4}}})
local base = oc.leftovers()

t.test("each value lands in every resolution, averages per point", function ()
  local start = 6000   -- a round time: minute 100, ten-minutes 10
  history.add("water", 10, start)
  history.add("water", 30, start + 30)
  history.add("water", 50, start + 60)
  local minutes = history.series("water", 60, 3, start + 60)
  t.equal(minutes.values[2], 20) t.equal(minutes.low[2], 10) t.equal(minutes.high[2], 30)
  t.equal(minutes.values[3], 50) t.equal(minutes.values[1], nil)
  local tens = history.series("water", 2, 2, start + 60)
  t.equal(tens.values[2], 30) t.equal(tens.seconds, 600)
end)

t.test("old points drop out of each resolution", function ()
  for minute = 0, 20 do history.add("pac", minute, minute * 60) end
  local minutes = history.series("pac", 60, 10, 20 * 60)
  t.equal(minutes.values[10], 20) t.equal(minutes.values[5], nil)   -- only 5 minutes kept
  t.equal(history.names()[1], "pac")
end)

t.test("saved and read back", function ()
  history.start()
  history.add("water", 99)
  history.stop()
  t.equal(oc.leftovers(), base)
  history.setup({filePath = path, saveSeconds = 300, levels = {{seconds = 60, keep = 5}, {seconds = 600, keep = 4}}})
  history.load()
  local series = history.series("water", 60, 1)
  t.equal(series.values[1], 99)
end)

filesystem.remove(path)
return t.finish()
