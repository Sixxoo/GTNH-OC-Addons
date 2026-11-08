local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

local addons = require("addons.core")
local component = require("component")
local gpu = oc.addScreen(160, 50, {3, 2})
local second = oc.addComponent("screen", {getAspectRatio = function () return 1, 1 end, isOn = function () return true end})
local ms = addons.load("multi-screen", {rows = 20})

t.test("each screen gets its resolution from its shape", function ()
  local list = ms.list()
  t.equal(#list, 2)
  local first = component.list("screen")()
  local w1, h1 = ms.open(list[1], 20)
  local w2, h2 = ms.open(second, 10)
  t.equal(h2, 10) t.equal(w2, 80)
  t.truthy(w1 >= 80) t.equal(h1, 20)
end)

t.test("frames: only changed rows are drawn, the shared GPU moves between screens", function ()
  local lines = {}
  for y = 1, 10 do lines[y] = "&0xFFFFFF;row "..y end
  t.equal(ms.show(second, lines), 10)
  t.equal(ms.show(second, lines), 0)
  lines[3] = "&0xFF0000;changed"
  t.equal(ms.show(second, lines), 1)
  t.equal(component.gpu.getScreen(), second)
  ms.redraw()
  t.equal(ms.show(second, lines), 10)
  ms.close()
end)

return t.finish()
