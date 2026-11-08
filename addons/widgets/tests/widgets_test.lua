local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

local addons = require("addons.core")
local ui = addons.load("neon-ui")
local widgets = addons.load("widgets")

local function text(cv)
  local rows = {}
  for y = 1, cv.height do rows[y] = table.concat(cv.char[y]) end
  return table.concat(rows, "\n")
end

t.test("tile, status, table and meter draw what they get", function ()
  local cv = ui.canvas(60, 20)
  widgets.tile(cv, 1, 1, 20, 5, "CYCLES", "1 234", {sub = "today", color = ui.colors.neon})
  widgets.status(cv, 22, 1, 30, {{label = "ME", state = "ok", text = "online"}, {label = "Power", state = "warning", text = "12%"}})
  local drawn = widgets.table(cv, 1, 7, 50, 4, {{title = "ITEM"}, {title = "AMOUNT", width = 10, align = "right"}},
    {{"Iron Ingot", "1 200"}, {"Gold Ingot", {"0", ui.colors.red}}, {"Copper", "5"}, {"Tin", "9"}})
  widgets.meter(cv, 1, 12, 30, "Disks", 75, 100)
  local all = text(cv)
  t.contains(all, "1 234") t.contains(all, "today") t.contains(all, "online")
  t.contains(all, "Iron Ingot") t.contains(all, "75%")
  t.equal(drawn, 3)
  t.snapshot("widgets", cv:lines())
end)

return t.finish()
