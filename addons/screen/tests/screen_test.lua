local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

local gpu, display = oc.addScreen(160, 50, {5, 3})
local addons = require("addons.core")
local screen = addons.load("screen")

-- Count what reaches the GPU
local sets = 0
local realSet = gpu.set
gpu.set = function (...) sets = sets + 1 return realSet(...) end

local function frame(text)
  local lines = {}
  local width, height = screen.size()
  for y = 1, height do
    lines[y] = "&&0x000000;&0xFFFFFF;"..(y == 1 and text or "")..string.rep(" ", width - (y == 1 and #text or 0))
  end
  return lines
end

t.test("a 5x3 screen at 35 rows gives 117 x 35", function ()
  local width, height = screen.open()
  t.equal(width, 117) t.equal(height, 35)
  t.equal(select(1, gpu.getResolution()), 117)
end)

t.test("the first frame draws every row, the next only what changed", function ()
  screen.redraw()
  t.equal(screen.show(frame("hello")), 35, "first frame")
  t.equal(screen.show(frame("hello")), 0, "same frame")
  t.equal(screen.show(frame("world")), 1, "one row changed")
  t.contains(display.text()[1], "world")
end)

t.test("colour codes reach the screen", function ()
  screen.redraw()
  local lines = frame("")
  lines[2] = "&&0x03050A;&0x00B4FF;NEON"..string.rep(" ", 113)
  screen.show(lines)
  local char, fg, bg = display.cell(1, 2)
  t.equal(char, "N") t.equal(fg, 0x00B4FF) t.equal(bg, 0x03050A)
end)

t.test("one colour run is one gpu.set", function ()
  screen.redraw()
  local lines = frame("")
  sets = 0
  screen.show(lines)
  t.equal(sets, 35, "one call per row")
end)

t.test("a lost screen is bound again and fully redrawn", function ()
  screen.show(frame("before"))
  display.unbind()
  t.equal(screen.show(frame("before")), 35, "everything drawn again")
  t.truthy(gpu.getScreen() ~= nil, "bound again")
end)

t.test("every 60 s a full frame, in case something else drew on the screen", function ()
  screen.show(frame("x"))
  t.equal(screen.show(frame("x")), 0)
  oc.advance(61)
  t.equal(screen.show(frame("x")), 35)
end)

t.test("close gives the largest resolution back", function ()
  screen.close()
  t.equal(select(1, gpu.getResolution()), 160)
end)

return t.finish()
