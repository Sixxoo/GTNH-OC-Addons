local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

local addons = require("addons.core")
local ui = addons.load("neon-ui")
local windows = addons.load("windows")
local keys = require("keyboard").keys

t.test("a question answered by key", function ()
  local wm = windows.new()
  local answer
  wm:confirm("SWITCH OFF?", {"The plant stops after this cycle."}, function (yes) answer = yes end)
  t.truthy(wm:isOpen())
  local cv = ui.canvas(60, 15)
  wm:draw(cv)
  t.snapshot("confirm", cv:lines())
  t.truthy(wm:key(string.byte("x"), 0))      -- taken, but not an answer
  t.truthy(wm:isOpen())
  wm:key(string.byte("n"), keys.n)
  t.equal(answer, false) t.falsy(wm:isOpen())
  t.falsy(wm:key(string.byte("n"), keys.n))  -- nothing open: the program gets keys again
end)

t.test("a message closed by a touch on OK, windows stack", function ()
  local wm = windows.new()
  local closed = {}
  wm:message("FIRST", "one", function (id) closed[#closed + 1] = "first "..tostring(id) end)
  wm:message("SECOND", "two", function (id) closed[#closed + 1] = "second "..tostring(id) end)
  local cv = ui.canvas(60, 15)
  wm:draw(cv)
  local hit = wm.hits[1]
  wm:touch(hit.from, hit.y)
  t.equal(closed[1], "second ok")
  wm:key(13, keys.enter)
  t.equal(closed[2], "first ok")
end)

return t.finish()
