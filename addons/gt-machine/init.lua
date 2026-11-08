-- GregTech machines as an adapter shows them (component gt_machine): find them by name, read their
-- state, switch them on and off, and read sensor lines by key. In GTNH 2.9 sensor lines are raw
-- translation keys with arguments ("kekztech.infodata.x\\4,424,885"), older versions English text,
-- so reading by key (or by a piece of text) keeps working where reading by line number breaks
local M = {}

function M.setup(settings)
  M.settings = settings
end

---Every gt_machine whose name matches a Lua pattern, e.g. "purificationunitozonation"
---@param pattern string
---@return table[] proxies
function M.findAll(pattern)
  local component = require("component")
  local found = {}

  for address in component.list("gt_machine") do
    local proxy = component.proxy(address)
    local isOk, name = pcall(proxy.getName)

    if isOk and type(name) == "string" and name:match(pattern) then
      found[#found + 1] = proxy
    end
  end

  return found
end

---The one gt_machine matching a pattern, or nil and why (none, or several)
---@param pattern string
---@return table|nil proxy
---@return string|nil problem
function M.find(pattern)
  local found = M.findAll(pattern)

  if #found == 0 then
    return nil, "no machine matches "..pattern.." (adapter touching the controller, or an MFU linked to it?)"
  elseif #found > 1 then
    return nil, #found.." machines match "..pattern..", use its address"
  end

  return found[1]
end

---State of a machine in one table
---@param proxy table
---@return table {working, progress, maxProgress, seconds, allowed}
function M.state(proxy)
  local progress, maxProgress = proxy.getWorkProgress() or 0, proxy.getWorkMaxProgress() or 0

  return {
    working = proxy.hasWork() == true,
    progress = progress,
    maxProgress = maxProgress,
    seconds = math.max(0, (maxProgress - progress) / 20),   -- left of the current recipe or cycle
    fraction = maxProgress > 0 and progress / maxProgress or 0,
    allowed = proxy.isWorkAllowed() == true,
  }
end

---Allow or stop work. A machine stopped mid-recipe finishes it first
function M.allow(proxy, allowed)
  proxy.setWorkAllowed(allowed == true)
end

-- ---------- sensor ----------

---Sensor lines split into key, arguments and plain text
---@param proxy table
---@return table[] lines {key, args = {...}, text}
function M.sensor(proxy)
  local isOk, raw = pcall(proxy.getSensorInformation)
  local lines = {}

  if not isOk or type(raw) ~= "table" then
    return lines
  end

  for _, line in ipairs(raw) do
    line = tostring(line):gsub("§.", "")
    local parts = {}

    -- Arguments are separated by two literal backslashes
    for part in (line.."\\\\"):gmatch("(.-)\\\\") do
      parts[#parts + 1] = part
    end

    lines[#lines + 1] = {key = parts[1], args = {table.unpack(parts, 2)}, text = line}
  end

  return lines
end

---A number from text: digits only, so thousands separators of any server language don't matter.
---"4,424,885" -> 4424885, "98.5%" -> 98.5 (a single dot with 1-2 digits after it is a decimal point)
---@param text string
---@return number|nil
function M.number(text)
  local cleaned = text ~= nil and tostring(text):match("%-?%d[%d%.,]*") or nil

  if cleaned == nil then
    return nil
  end

  local negative = cleaned:sub(1, 1) == "-"
  cleaned = cleaned:gsub("^%-", ""):gsub("[%.,]$", "")
  local whole, decimal = cleaned:match("^(.-)[%.,](%d%d?)$")

  if whole == nil then
    whole, decimal = cleaned, nil
  end

  whole = whole:gsub("[^%d]", "")
  local value = tonumber(whole ~= "" and whole or "0") + (decimal and tonumber(decimal) / 10 ^ #decimal or 0)

  return negative and -value or value
end

---First sensor line whose key or text contains a piece (plain text, not a pattern)
---@param proxy table
---@param piece string
---@return table|nil line {key, args, text}
function M.line(proxy, piece)
  for _, line in ipairs(M.sensor(proxy)) do
    if (line.key and line.key:find(piece, 1, true)) or line.text:find(piece, 1, true) then
      return line
    end
  end

  return nil
end

---A number from the sensor line with a piece of key or text: its first argument, or the number in its text
---@param proxy table
---@param piece string
---@param argument? integer Which argument, default 1
---@return number|nil
function M.read(proxy, piece, argument)
  local line = M.line(proxy, piece)

  if line == nil then
    return nil
  end

  if #line.args > 0 then
    return M.number(line.args[argument or 1])
  end

  return M.number(line.text:match("[%-%d][%d,%. ]*") or line.text)
end

return M
