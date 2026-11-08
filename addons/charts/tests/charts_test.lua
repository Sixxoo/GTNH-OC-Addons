local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

local addons = require("addons.core")
local ui = addons.load("neon-ui")
local charts = addons.load("charts")

local function text(cv)
  local rows = {}
  for y = 1, cv.height do rows[y] = table.concat(cv.char[y]) end
  return rows
end

t.test("columns scale to the highest value, labels under", function ()
  local cv = ui.canvas(30, 8)
  local width = charts.columns(cv, 1, 1, 30, 8, {1, 2, 4, nil, 4}, {labels = {"a", "b", "c", "d", "e"}, labelEvery = 2})
  t.equal(width, 6)
  local rows = text(cv)
  t.contains(rows[1], "█████")              -- 4 = full height
  t.equal(rows[8]:gsub("%s", ""), "ace")  -- every second label from the right
  t.snapshot("columns", cv:lines())
end)

t.test("sparkline: low to high, nil as a gap", function ()
  local cv = ui.canvas(10, 1)
  charts.sparkline(cv, 1, 1, 10, {0, 7, 14, nil, 7})
  t.equal(text(cv)[1]:sub(1, 13), "▁▅█ ▅")
end)

t.test("bars: label, bar, value", function ()
  local cv = ui.canvas(40, 2)
  charts.bars(cv, 1, 1, 40, {{label = "Iron", value = 50}, {label = "Gold", value = 100, text = "100k"}}, {labelWidth = 6})
  local rows = text(cv)
  t.contains(rows[1], "Iron") t.contains(rows[2], "100k")
  t.contains(rows[2], string.rep("━", 24))
end)

return t.finish()
