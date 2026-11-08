local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

local addons = require("addons.core")
local ui = addons.load("neon-ui")
local big = addons.load("big-font")

t.test("width and drawing", function ()
  t.equal(big.width("12"), 7)
  t.equal(big.width("M"), 5)
  local cv = ui.canvas(30, 5)
  t.equal(big.draw(cv, 1, 1, "10%"), 11)
  t.equal(cv.char[1][2], "█") t.equal(cv.char[1][1], " ")   -- the 1: " # "
  t.equal(cv.char[5][1], "█") t.equal(cv.char[5][3], "█")
  t.snapshot("big", cv:lines())
end)

t.test("lower case and unknown characters", function ()
  t.equal(big.width("ok"), big.width("OK"))
  t.equal(big.width("~"), 2)
end)

return t.finish()
