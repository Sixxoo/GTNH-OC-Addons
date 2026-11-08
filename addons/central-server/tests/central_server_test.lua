local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

local event = require("event")
local addons = require("addons.core")
oc.modem()
local central = addons.load("central-server", {name = "Water", reportSeconds = 30, offlineSeconds = 120})
local logs = {}
event.listen("log_warning", function (_, text) logs[#logs + 1] = text end)
event.listen("log_info", function (_, text) logs[#logs + 1] = text end)

t.test("a client report shows on the server", function ()
  central.startServer()
  central.startClient({program = "water-line", status = "running", values = {cycles = 12}})
  local list = central.computers()
  t.equal(#list, 1)
  t.equal(list[1].name, "Water") t.equal(list[1].program, "water-line") t.equal(list[1].values.cycles, 12)
  t.truthy(list[1].online)
end)

t.test("a quiet computer goes offline, and comes back", function ()
  central.stopClient()              -- sends "stopped" once, then nothing
  oc.advance(130)
  t.falsy(central.computers()[1].online)
  t.contains(logs[#logs], "Water is offline")
  central.startClient()
  t.truthy(central.computers()[1].online)
  t.contains(logs[#logs], "Water is back")
  central.stopClient()
  central.stopServer()
end)

return t.finish()
