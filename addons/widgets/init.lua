-- Ready-made pieces on top of neon-ui: a tile with one big value, status lights, a table with
-- aligned columns and a labelled meter
local M = {}

function M.setup(settings)
  M.settings = settings
end

local function ui()
  return require("addons.core").load("neon-ui")
end

---A tile: a card with a title, one value in the middle and a line under it
---@param options table|nil {color, sub, subColor}
function M.tile(cv, x, y, w, h, title, value, options)
  options = options or {}
  local C = ui().colors
  ui().card(cv, x, y, w, h, title)
  local text = ui().fit(tostring(value), w - 4)
  local middle = y + math.max(1, math.floor((h - 1) / 2))

  if options.sub ~= nil and h >= 4 then
    middle = y + math.max(1, math.floor((h - 2) / 2))
  end

  cv:put(x + math.floor((w - ui().length(text)) / 2), middle, text, options.color or C.text, C.card)

  if options.sub ~= nil and h >= 4 then
    local sub = ui().fit(tostring(options.sub), w - 4)
    cv:put(x + math.floor((w - ui().length(sub)) / 2), middle + 1, sub, options.subColor or C.na, C.card)
  end
end

local lights = {ok = "green", warning = "amber", error = "red", off = "na", busy = "neon"}

---Status lights: "● label .... text", one row each. items: {{label, state = "ok"|"warning"|"error"|"off"|"busy", text}}
function M.status(cv, x, y, w, items, bg)
  local C = ui().colors

  for i, item in ipairs(items) do
    local color = C[lights[item.state or item[2]] or "na"]
    local rowY = y + i - 1
    cv:put(x, rowY, "●", color, bg)
    ui().row(cv, x + 2, rowY, w - 2, item.label or item[1], item.text or item[3], color, bg)
  end
end

---A table: header row and rows, columns {{title, width, align = "left"|"right", color}}, cells as text or
---{text, color}. Returns the rows drawn
function M.table(cv, x, y, w, h, columns, rows, bg)
  local C = ui().colors
  local fixed, flexible = 0, 0

  for _, column in ipairs(columns) do
    if column.width then fixed = fixed + column.width + 1 else flexible = flexible + 1 end
  end

  local spare = math.max(1, math.floor((w - fixed) / math.max(1, flexible)))

  local function cell(text, column, cx, cy, width, color)
    text = ui().fit(tostring(text or ""), width)

    if column.align == "right" then
      cx = cx + width - ui().length(text)
    end

    cv:put(cx, cy, text, color, bg)
  end

  local cx = x

  for _, column in ipairs(columns) do
    local width = column.width or spare
    cell(column.title or "", column, cx, y, width, C.na)
    cx = cx + width + 1
  end

  local drawn = 0

  for r, values in ipairs(rows) do
    local cy = y + r

    if cy > y + h - 1 then
      break
    end

    cx = x

    for c, column in ipairs(columns) do
      local width = column.width or spare
      local value = values[c]
      local text, color = value, column.color or C.text

      if type(value) == "table" then
        text, color = value[1], value[2] or color
      end

      cell(text, column, cx, cy, width, color)
      cx = cx + width + 1
    end

    drawn = r
  end

  return drawn
end

---A meter: label and value on one row, a bar under it
---@param options table|nil {color, text, bg}
function M.meter(cv, x, y, w, label, value, max, options)
  options = options or {}
  local C = ui().colors
  local fraction = (max or 0) > 0 and value / max or 0
  ui().row(cv, x, y, w, label, options.text or (math.floor(fraction * 100 + 0.5).."%"), options.color or C.text, options.bg)
  ui().bar(cv, x, y + 1, w, math.min(1, math.max(0, fraction)), {color = options.color or C.neon, bg = options.bg, slider = false})
end

return M
