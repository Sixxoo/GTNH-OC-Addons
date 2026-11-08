-- Space on the storage cells in ME Drives. The ME network itself tells OC nothing about bytes, but a
-- transposer next to an ME Drive sees the cells, and OC adds totalBytes/usedBytes/types to each item
-- cell. Fluid cells don't report bytes; they are counted as "unknown"
local M = {}

local timer, full = nil, false

local sideNames = {[0] = "down", "up", "north", "south", "west", "east"}
local sideNumbers = {down = 0, bottom = 0, up = 1, top = 1, north = 2, back = 2, south = 3, front = 3,
  west = 4, right = 4, east = 5, left = 5}

function M.setup(settings)
  M.settings = settings
  full = false
end

local function isCell(stack)
  return type(stack) == "table" and stack.totalBytes ~= nil
end

local function stacks(proxy, side)
  local size = proxy.getInventorySize(side)

  if type(size) ~= "number" or size <= 0 then
    return nil
  end

  local list = {}
  local isOk, all = pcall(proxy.getAllStacks, side)

  if isOk and all ~= nil and all.getAll ~= nil then
    for _, stack in pairs(all.getAll()) do
      if type(stack) == "table" and stack.name ~= nil then
        list[#list + 1] = stack
      end
    end
  else
    for slot = 1, size do
      local stack = proxy.getStackInSlot(side, slot)

      if type(stack) == "table" and stack.name ~= nil then
        list[#list + 1] = stack
      end
    end
  end

  return list
end

local function drive(proxy, side)
  local list = stacks(proxy, side)

  if list == nil then
    return nil
  end

  local cells, unknown = {}, 0

  for _, stack in ipairs(list) do
    if isCell(stack) then
      cells[#cells + 1] = {label = stack.label or stack.name, totalBytes = stack.totalBytes or 0,
        usedBytes = stack.usedBytes or 0, types = stack.storedItemTypes or 0, totalTypes = stack.getTotalItemTypes or 0}
    elseif (tostring(stack.name)..tostring(stack.label)):lower():find("cell") or tostring(stack.name):find("fluid_storage") then
      unknown = unknown + 1
    end
  end

  return {transposer = proxy.address, side = sideNames[side], cells = cells, unknown = unknown}
end

---The drives to read: from settings.drives, or every side of every transposer with cells
---@return table[] drives
---@return string|nil problem
function M.scan()
  local component = require("component")
  local found = {}

  if #(M.settings.drives or {}) > 0 then
    for _, entry in ipairs(M.settings.drives) do
      local address = component.get(entry.transposer, "transposer")

      if address == nil then
        return found, "[me-capacity] no transposer "..tostring(entry.transposer)
      end

      local side = type(entry.side) == "number" and entry.side or sideNumbers[tostring(entry.side):lower()]

      if side == nil then
        return found, "[me-capacity] unknown side "..tostring(entry.side)
      end

      found[#found + 1] = drive(component.proxy(address), side) or
        {transposer = address, side = sideNames[side], cells = {}, unknown = 0}
    end

    return found
  end

  for address in component.list("transposer") do
    local proxy = component.proxy(address)

    for side = 0, 5 do
      local isOk, result = pcall(drive, proxy, side)

      if isOk and result ~= nil and (#result.cells > 0 or result.unknown > 0) then
        found[#found + 1] = result
      end
    end
  end

  return found
end

---Space on all cells: {totalBytes, usedBytes, freeBytes, fraction, types, totalTypes, cells, unknown, drives}
---@return table
---@return string|nil problem
function M.read()
  local drives, problem = M.scan()
  local result = {totalBytes = 0, usedBytes = 0, types = 0, totalTypes = 0, cells = 0, unknown = 0, drives = drives}

  for _, found in ipairs(drives) do
    for _, cell in ipairs(found.cells) do
      result.totalBytes = result.totalBytes + cell.totalBytes
      result.usedBytes = result.usedBytes + cell.usedBytes
      result.types = result.types + cell.types
      result.totalTypes = result.totalTypes + cell.totalTypes
      result.cells = result.cells + 1
    end

    result.unknown = result.unknown + found.unknown
  end

  result.freeBytes = result.totalBytes - result.usedBytes
  result.fraction = result.totalBytes > 0 and result.usedBytes / result.totalBytes or 0
  return result, problem
end

---Read the cells and log when they get full (once) and when there is room again
---@return table
function M.check()
  local event = require("event")
  local result, problem = M.read()

  if problem ~= nil then
    event.push("log_error", problem)
  end

  local percent = math.floor(result.fraction * 100 + 0.5)

  if not full and result.cells > 0 and percent >= M.settings.warnPercent then
    full = true
    event.push("log_warning", "[ME] Storage cells are "..percent.."% full")
  elseif full and percent < M.settings.warnPercent then
    full = false
    event.push("log_info", "[ME] Storage cells have room again ("..percent.."%)")
  end

  return result
end

function M.start()
  local event = require("event")
  M.stop()

  timer = event.timer(M.settings.intervalSeconds, function ()
    local isOk, problem = pcall(M.check)

    if not isOk then
      event.push("log_error", "[ME] "..tostring(problem))
    end
  end, math.huge)

  pcall(M.check)
end

function M.stop()
  if timer ~= nil then
    require("event").cancel(timer)
    timer = nil
  end
end

return M
