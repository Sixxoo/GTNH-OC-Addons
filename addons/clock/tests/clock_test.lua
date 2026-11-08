local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

local addons = require("addons.core")
local tmp = os.tmpname()
local clock = addons.load("clock", {timeZone = 1, tmpFile = tmp})

t.test("now is the real clock plus the time zone", function ()
  t.equal(clock.now(), math.floor(oc.realTimeMs() / 1000) + 3600)
end)

t.test("between reads it counts on from the uptime", function ()
  local first = clock.now()
  oc.advance(10)
  t.equal(clock.now() - first, 10)
end)

t.test("format uses os.date", function ()
  local time = clock.now()
  t.equal(clock.format("%H:%M", time), os.date("%H:%M", time))
end)

t.test("a file that can't be written names the addon", function ()
  local broken = addons.load("clock", {tmpFile = "/no/such/folder/x"})
  t.errors(function () broken.now() end, "[clock]")
end)

os.remove(tmp)
return t.finish()
