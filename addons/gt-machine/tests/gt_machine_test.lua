local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

local addons = require("addons.core")
local gt = addons.load("gt-machine")
local component = require("component")

local plantAddress, plantState = oc.gtMachine("multimachine.purificationplant",
  {work = true, progress = 600, maxProgress = 2400})
oc.gtMachine("multimachine.purificationunitclarifier")
oc.gtMachine("multimachine.purificationunitozonation")
local lscAddress = oc.gtMachine("multimachine.supercapacitor", {sensor = {
  "kekztech.infodata.lapotronic_super_capacitor.eu_stored\\\\4,424,885,923",
  "§aSuccess chance: §e98.5%",
  "Plain line without numbers",
}})

t.test("find one machine by name", function ()
  local plant = gt.find("purificationplant")
  t.equal(plant.address, plantAddress)
end)

t.test("several or none: nil and why", function ()
  local proxy, problem = gt.find("purificationunit")
  t.equal(proxy, nil) t.contains(problem, "2 machines")
  proxy, problem = gt.find("nothing")
  t.equal(proxy, nil) t.contains(problem, "MFU")
  t.equal(#gt.findAll("purificationunit"), 2)
end)

t.test("state: working, seconds left, fraction", function ()
  local state = gt.state(component.proxy(plantAddress))
  t.truthy(state.working)
  t.equal(state.seconds, 90)
  t.equal(state.fraction, 0.25)
end)

t.test("allow switches work", function ()
  gt.allow(component.proxy(plantAddress), false)
  t.equal(plantState.allowed, false)
  gt.allow(component.proxy(plantAddress), true)
  t.equal(plantState.allowed, true)
end)

t.test("sensor lines split into key and arguments, colour codes gone", function ()
  local lines = gt.sensor(component.proxy(lscAddress))
  t.equal(lines[1].key, "kekztech.infodata.lapotronic_super_capacitor.eu_stored")
  t.equal(lines[1].args[1], "4,424,885,923")
  t.equal(lines[2].text, "Success chance: 98.5%")
end)

t.test("read by a piece of key or text", function ()
  local lsc = component.proxy(lscAddress)
  t.equal(gt.read(lsc, "eu_stored"), 4424885923)
  t.equal(gt.read(lsc, "Success"), 98.5)
  t.equal(gt.read(lsc, "Plain line"), nil)
  t.equal(gt.read(lsc, "missing"), nil)
end)

t.test("numbers with any thousands separator", function ()
  t.equal(gt.number("4,424,885"), 4424885)
  t.equal(gt.number("4.424.885"), 4424885)
  t.equal(gt.number("4 424 885 EU"), 4)  -- a space ends the number: the sensor uses commas or dots
  t.equal(gt.number("98,5 %"), 98.5)
  t.equal(gt.number("-1,200"), -1200)
  t.equal(gt.number("no number"), nil)
end)

return t.finish()
