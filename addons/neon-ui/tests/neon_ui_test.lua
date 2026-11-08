local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

local addons = require("addons.core")
local ui = addons.load("neon-ui")
local C = ui.colors

local function cell(cv, x, y)
  return cv.char[y][x], cv.fg[y][x], cv.bg[y][x]
end

t.test("canvas lines carry colour codes and skip foreground codes for spaces", function ()
  local cv = ui.canvas(6, 1)
  cv:put(2, 1, "AB", 0x123456, 0x000001)
  t.equal(cv:lines()[1], "&&0x03050A; &&0x000001;&0x123456;AB&&0x03050A;   ")
end)

t.test("card: blue frame, red corners top left and bottom right, title and right value", function ()
  local cv = ui.canvas(20, 4)
  ui.card(cv, 1, 1, 20, 4, "CYCLE", {right = "RUNNING", rightColor = C.green})

  local char, fg = cell(cv, 1, 1)
  t.equal(char, "┌") t.equal(fg, C.red, "top left corner")
  char, fg = cell(cv, 20, 4)
  t.equal(char, "┘") t.equal(fg, C.red, "bottom right corner")
  char, fg = cell(cv, 20, 1)
  t.equal(char, "┐") t.equal(fg, C.neon, "top right is blue")
  t.contains(table.concat(cv.char[1]), " CYCLE ")
  t.contains(table.concat(cv.char[1]), " RUNNING ")
end)

t.test("bar: slider at the start, middle and end", function ()
  for _, case in ipairs({{0, 1}, {0.5, 6}, {1, 10}, {1.4, 10}}) do
    local cv = ui.canvas(10, 1)
    ui.bar(cv, 1, 1, 10, case[1])
    local char, fg = cell(cv, case[2], 1)
    t.equal(char, "┃", "slider char at "..case[1])
    t.equal(fg, C.red, "slider colour at "..case[1])
  end
end)

t.test("bar: heavy line up to the fraction, light line after", function ()
  local cv = ui.canvas(10, 1)
  ui.bar(cv, 1, 1, 10, 0.5, {slider = false, color = C.yellow})
  t.equal(table.concat(cv.char[1]), "━━━━━─────")
  t.equal(cv.fg[1][1], C.yellow)
  t.equal(cv.fg[1][10], C.track)
end)

t.test("levelColor picks the first step the value is under", function ()
  local steps = {{below = 1e6, color = C.red}, {below = 8e6, color = C.orange}, {below = 30e6, color = C.yellow}}
  t.equal(ui.levelColor(0.5e6, steps), C.red)
  t.equal(ui.levelColor(1e6, steps), C.orange)
  t.equal(ui.levelColor(29.9e6, steps), C.yellow)
  t.equal(ui.levelColor(30e6, steps), C.green)
end)

t.test("fit cuts with a dot, duration reads well", function ()
  t.equal(ui.fit("Flocculated Water", 8), "Floccul.")
  t.equal(ui.fit("short", 8), "short")
  t.equal(ui.duration(73), "1m 13s")
  t.equal(ui.duration(15300), "4h 15m")
end)

t.test("log keeps the offset in range and colours named codes", function ()
  local cv = ui.canvas(30, 5)
  local offset = ui.log(cv, 1, 1, 30, 5, "EVENT LOG", {"&cyan;one", "&red;two", "three", "four"}, 99)
  t.equal(offset, 1, "offset kept in range")
  t.equal(cv.char[2][3], "t", "first shown line is the second")
  t.equal(cv.fg[2][3], C.red)
end)

t.test("theme changes colours, corners can be turned off", function ()
  local red = addons.load("neon-ui", {theme = {neon = 0xFF0000}, corners = false})
  local cv = red.canvas(10, 3)
  red.card(cv, 1, 1, 10, 3, "X")
  t.equal(cv.fg[1][1], 0xFF0000, "frame colour from the theme, no red corner")
  addons.load("neon-ui")
end)

t.test("a full screen in the neon style", function ()
  local cv = ui.canvas(117, 35)
  ui.header(cv, {clock = "19:30:00", title = "NEON UI", by = "by Sixxo", status = "RUNNING", badge = "DEMO", version = "1.0.0"})
  ui.card(cv, 1, 3, 58, 10, "UNITS", {right = "STOCK / TARGET"})
  local rows = {{"T1 CLARIFIER", 0.9, C.green}, {"T2 OZONATION", 0.4, C.yellow}, {"T3 FLOCCULATION", 0.02, C.red}}
  for i, row in ipairs(rows) do
    local y = 3 + (i - 1) * 3
    ui.row(cv, 3, y + 1, 54, row[1], math.floor(row[2] * 100).."%", row[3], C.card)
    ui.bar(cv, 3, y + 2, 54, row[2], {color = row[3], bg = C.card})
  end
  ui.card(cv, 60, 3, 58, 6, "CYCLE", {right = "RUNNING", rightColor = C.green})
  ui.row(cv, 62, 4, 54, "NEXT CYCLE IN", ui.duration(73), C.text, C.card)
  ui.bar(cv, 62, 5, 54, 0.4, {bg = C.card, slider = false})
  ui.log(cv, 60, 9, 58, 26, "EVENT LOG", {"&lightGray;19:29 &cyan;[QC] Next cycle: T2", "&lightGray;19:28 &white;Started"}, 0)
  ui.footer(cv, {keys = {{"↑↓", "log"}, {"Q", "quit"}}, legend = {{"▶", "next cycle", C.neon}, {"✗", "needs attention", C.red}}})

  t.equal(#cv:lines(), 35)
  t.snapshot("demo", cv:lines())
end)

return t.finish()
