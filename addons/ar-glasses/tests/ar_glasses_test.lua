local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

local addons = require("addons.core")
local glasses = addons.load("ar-glasses")

t.test("no glasses terminal: false and why", function ()
  t.falsy(glasses.set("power", "Power 50%"))
  local _, problem = glasses.find()
  t.contains(problem, "glasses terminal")
end)

local widgets, calls = {}, 0
local function widget(kind)
  local w = {kind = kind}
  for _, name in ipairs({"setText", "setColor", "setPosition", "setScale", "setSize", "setAlpha"}) do
    w[name] = function (...) calls = calls + 1 w[name.."Args"] = table.pack(...) end
  end
  widgets[#widgets + 1] = w
  return w
end
oc.addComponent("glasses", {
  addTextLabel = function () return widget("text") end,
  addRect = function () return widget("rect") end,
  removeAll = function () widgets = {} end,
  getBindPlayers = function () return {"Steve"} end,
})

t.test("lines are made once and changed only when needed", function ()
  t.truthy(glasses.set("power", "Power 50%", 0x2BE05A))
  t.truthy(glasses.set("me", "ME 70%"))
  t.equal(#widgets, 3)   -- background box + 2 lines
  local before = calls
  glasses.set("power", "Power 50%", 0x2BE05A)
  t.equal(calls, before)
  glasses.set("power", "Power 40%", 0x2BE05A)
  t.equal(calls, before + 1)
  t.equal(widgets[2].setTextArgs[1], "Power 40%")
  t.equal(widgets[3].setPositionArgs[2], 4 + 2 + 10)
end)

t.test("remove, players, clear", function ()
  glasses.remove("power")
  t.equal(widgets[3].setPositionArgs[2], 4 + 2)
  t.equal(glasses.players()[1], "Steve")
  glasses.clear()
  t.equal(#widgets, 0)
end)

return t.finish()
