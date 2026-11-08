-- Charts drawn on a neon-ui canvas. Columns use full blocks (stacked rows join into one column),
-- sparklines the eighth blocks ▁▂▃▄▅▆▇█, both one cell wide in the OpenComputers font
local M = {}

local spark = {"▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"}

function M.setup(settings)
  M.settings = settings
end

local function ui()
  return require("addons.core").load("neon-ui")
end

local function highest(values, floor)
  local top = floor or 0

  for _, value in pairs(values) do
    if type(value) == "number" and value > top then
      top = value
    end
  end

  return top
end

---Columns, one per value (nil = no column), oldest left. Labels go under the baseline
---@param options table|nil {max, color, lastColor, labels = {}, labelEvery = 1, values = bool (number on top), gap = 1}
---@return integer columnWidth
function M.columns(cv, x, y, w, h, values, options)
  options = options or {}
  local C = ui().colors
  local count = #values
  local hasLabels = options.labels ~= nil
  local rows = h - (hasLabels and 2 or 1)
  local gap = options.gap or 1
  local width = math.max(1 + gap, math.floor(w / math.max(1, count)))
  local left = x + math.floor((w - width * count) / 2)
  local top = options.max or highest(values)
  local bottom = y + rows - 1

  cv:put(left, bottom + 1, string.rep("─", width * count), C.track)

  for i = 1, count do
    local value = values[i]
    local columnX = left + (i - 1) * width
    local color = (i == count and options.lastColor) or options.color or C.sub

    if type(value) == "number" and value > 0 and top > 0 then
      local height = math.max(1, math.floor(math.min(value, top) / top * rows + 0.5))

      for r = 1, height do
        cv:put(columnX, bottom - r + 1, string.rep("█", width - gap), color)
      end

      if options.values and height < rows then
        local text = tostring(value)

        if ui().length(text) <= width then
          cv:put(columnX, bottom - height, text, C.na)
        end
      end
    end

    local label = hasLabels and options.labels[i]

    if label and (count - i) % (options.labelEvery or 1) == 0 then
      cv:put(columnX, bottom + 2, label, i == count and (options.lastColor or C.neon) or C.na)
    end
  end

  return width
end

---One row: each value as an eighth block (nil = space), scaled between min and max of the values
---@param options table|nil {min, max, color}
function M.sparkline(cv, x, y, w, values, options)
  options = options or {}
  local first = math.max(1, #values - w + 1)
  local low, high = options.min, options.max

  for i = first, #values do
    local value = values[i]

    if type(value) == "number" then
      low = low and math.min(low, value) or value
      high = high and math.max(high, value) or value
    end
  end

  local text = {}

  for i = first, #values do
    local value = values[i]

    if type(value) ~= "number" or low == nil then
      text[#text + 1] = " "
    elseif high == low then
      text[#text + 1] = spark[4]
    else
      local level = math.floor((value - low) / (high - low) * 7 + 0.5) + 1
      text[#text + 1] = spark[math.max(1, math.min(8, level))]
    end
  end

  cv:put(x, y, table.concat(text), options.color or ui().colors.neon)
end

---Horizontal bars, one row each: label, bar, value. items: {{label, value, color?, text?}}
---@param options table|nil {max, labelWidth, valueWidth}
function M.bars(cv, x, y, w, items, options)
  options = options or {}
  local C = ui().colors
  local values = {}

  for i, item in ipairs(items) do
    values[i] = item.value or item[2]
  end

  local top = options.max or highest(values)
  local labelWidth = options.labelWidth or 12
  local valueWidth = options.valueWidth or 8
  local barWidth = w - labelWidth - valueWidth - 2

  for i, item in ipairs(items) do
    local rowY = y + i - 1
    local value = values[i] or 0
    local fraction = top > 0 and math.max(0, math.min(1, value / top)) or 0
    local filled = math.floor(fraction * barWidth + 0.5)
    local text = item.text or tostring(value)

    cv:put(x, rowY, ui().fit(item.label or item[1] or "", labelWidth), C.dim)
    cv:put(x + labelWidth + 1, rowY, string.rep("━", filled), item.color or item[3] or C.neon)
    cv:put(x + labelWidth + 1 + filled, rowY, string.rep("─", barWidth - filled), C.track)
    cv:put(x + w - ui().length(text), rowY, ui().fit(text, valueWidth), C.text)
  end
end

return M
