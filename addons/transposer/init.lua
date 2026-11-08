-- Transposers: find where a fluid or an item is (on any side but the hatch's), and move it into the
-- hatch on a configurable side. Copes with the OC quirks: getTankCount gives nil on a side without a
-- tank, getFluidInTank errors on a bad index, an empty tank has no name or amount
local M = {}

local sideNames = {down = 0, bottom = 0, up = 1, top = 1, north = 2, south = 3, west = 4, east = 5}
local names = {[0] = "down", "up", "north", "south", "west", "east"}

function M.setup(settings)
  M.settings = settings
end

---A side from a name ("down", "up", "north", "south", "west", "east") or a number 0-5
---@return integer|nil
function M.side(value)
  if type(value) == "number" and value >= 0 and value <= 5 then
    return value
  end

  return value ~= nil and sideNames[tostring(value):lower()] or nil
end

---Name of a side number
function M.sideName(side)
  return names[side] or tostring(side)
end

local function sidesExcept(ignore)
  local skip = {}

  for _, side in ipairs(ignore or {}) do
    skip[M.side(side)] = true
  end

  local list = {}

  for side = 0, 5 do
    if not skip[side] then
      list[#list + 1] = side
    end
  end

  return list
end

---Every tank the transposer sees: {side, tank, name, amount, capacity}; empty tanks have no name
---@param proxy table
---@param ignore? table Sides to skip
---@return table[]
function M.tanks(proxy, ignore)
  local found = {}

  for _, side in ipairs(sidesExcept(ignore)) do
    local isOk, count = pcall(proxy.getTankCount, side)

    if isOk and type(count) == "number" then
      for tank = 1, count do
        local readOk, fluid = pcall(proxy.getFluidInTank, side, tank)

        if readOk and type(fluid) == "table" then
          found[#found + 1] = {side = side, tank = tank, name = fluid.name, amount = fluid.amount or 0,
            capacity = fluid.capacity or 0}
        end
      end
    end
  end

  return found
end

---Where each fluid is: name -> {side, tank, amount}. Fluids not found are listed second
---@param proxy table
---@param fluids string[] Fluid names, e.g. {"polyaluminiumchloride"}
---@param ignore? table Sides to skip, normally the hatch's
---@return table found
---@return string[] missing
function M.findFluids(proxy, fluids, ignore)
  local found, missing = {}, {}

  for _, tank in ipairs(M.tanks(proxy, ignore)) do
    for _, name in ipairs(fluids) do
      if found[name] == nil and tank.name == name then
        found[name] = tank
      end
    end
  end

  for _, name in ipairs(fluids) do
    if found[name] == nil then
      missing[#missing + 1] = name
    end
  end

  return found, missing
end

---Where each item is: label -> {side, slot, size}. Labels not found are listed second
---@param proxy table
---@param labels string[] Item labels, e.g. {"Sodium Hydroxide Dust"}
---@param ignore? table Sides to skip
---@return table found
---@return string[] missing
function M.findItems(proxy, labels, ignore)
  local found, missing = {}, {}

  for _, side in ipairs(sidesExcept(ignore)) do
    local isOk, stacks = pcall(proxy.getAllStacks, side)

    if isOk and stacks ~= nil then
      for index, stack in pairs(stacks.getAll()) do
        if type(stack) == "table" and stack.label ~= nil then
          for _, label in ipairs(labels) do
            if found[label] == nil and stack.label == label then
              found[label] = {side = side, slot = index + 1, size = stack.size or 0}
            end
          end
        end
      end
    end
  end

  for _, label in ipairs(labels) do
    if found[label] == nil then
      missing[#missing + 1] = label
    end
  end

  return found, missing
end

---What the transposer sees on each side, for a "where is my tank" check: lines like "up: polyaluminiumchloride 4000000"
---@param proxy table
---@return string[]
function M.describe(proxy)
  local lines = {}

  for side = 0, 5 do
    local isOk, count = pcall(proxy.getTankCount, side)
    local text = M.sideName(side)..": "

    if not isOk or count == nil then
      text = text.."nothing"
    elseif count == 0 then
      text = text.."no tank"
    else
      local parts = {}

      for tank = 1, count do
        local readOk, fluid = pcall(proxy.getFluidInTank, side, tank)
        parts[#parts + 1] = (readOk and fluid and fluid.name) and (fluid.name.." "..(fluid.amount or 0)) or "empty tank"
      end

      text = text..table.concat(parts, ", ")
    end

    lines[#lines + 1] = text
  end

  return lines
end

---Move fluid into the hatch. Returns how much arrived, which can be less than asked
---(a transposer moves per call as much as its Fluid Regulator allows)
---@param proxy table
---@param from table {side, tank} from findFluids
---@param hatchSide integer|string
---@param amount integer
---@return integer moved
function M.moveFluid(proxy, from, hatchSide, amount)
  local isOk, result, moved = pcall(proxy.transferFluid, from.side, M.side(hatchSide), amount, from.tank)

  if not isOk or not result then
    return 0
  end

  return tonumber(moved) or amount
end

---Move fluid in as many calls as needed, until amount arrived or nothing more moves
---@return integer moved
function M.fill(proxy, from, hatchSide, amount)
  local total = 0

  while total < amount do
    local moved = M.moveFluid(proxy, from, hatchSide, amount - total)

    if moved <= 0 then
      break
    end

    total = total + moved
  end

  return total
end

---Move items into the hatch or bus. Returns how many arrived
---@param proxy table
---@param from table {side, slot} from findItems
---@param hatchSide integer|string
---@param count integer
---@return integer moved
function M.moveItems(proxy, from, hatchSide, count)
  local isOk, moved = pcall(proxy.transferItem, from.side, M.side(hatchSide), count, from.slot)
  return isOk and (tonumber(moved) or 0) or 0
end

return M
