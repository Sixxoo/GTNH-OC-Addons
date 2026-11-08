local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

local addons = require("addons.core")
local wiring = addons.load("wiring-check")
local me = oc.meInterface({}, {}, "0604d547-0b75-4990-bd55-4ac86f1df51d")
local tp = oc.transposer({}, {}, "5dcf2167-a9de-4f5a-8727-8287e7e4d98e")
oc.transposer({}, {}, "aaaa1111-0000-0000-0000-000000000000")
oc.transposer({}, {}, "bbbb2222-0000-0000-0000-000000000000")

local list = {
  {name = "[QC] ME Interface", type = "me_interface", address = "261af9d4-a03b-4b15-b1f0-ddbcda629cf7"},
  {name = "[T3] Transposer", type = "transposer", address = "5dcf"},
  {name = "[T4] Transposer", type = "transposer", address = "cccc3333"},
  {name = "[T5] Transposer", type = "transposer", address = ""},
}

t.test("missing ones with the unused ones of their type", function ()
  local result = wiring.check(list)
  t.falsy(result.ok) t.equal(result.missing, 2)
  t.equal(result.rows[1].candidates[1], me)
  t.equal(#result.rows[3].candidates, 2)
  local problems = wiring.problems(result)
  t.contains(problems[1], "one unused me_interface: "..me)
  t.contains(problems[2], "unused transposer: aaaa1111, bbbb2222")
end)

t.test("repair writes the one candidate into the config", function ()
  local path = os.tmpname()
  local file = io.open(path, "w")
  file:write('meInterfaceAddress = "261af9d4-a03b-4b15-b1f0-ddbcda629cf7",\n') file:close()
  local asked
  local result = wiring.repair(list, path, function (question) asked = question return true end)
  t.contains(asked, "Use the unused me_interface 0604d547")
  file = io.open(path) local text = file:read("*a") file:close() os.remove(path)
  t.contains(text, '"'..me..'"')
  t.equal(result.missing, 1)
end)

t.test("inventory by type", function ()
  local all = wiring.inventory()
  t.equal(#all.transposer, 3) t.equal(all.me_interface[1], me)
  t.truthy(tp ~= nil)
end)

return t.finish()
