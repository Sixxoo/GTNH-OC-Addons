-- The ME network through an adapter on an ME interface (me_interface) or controller (me_controller).
-- One way to name what you want: "fluid:water", "minecraft:iron_ingot", "gregtech:gt.blockores:86"
-- (name:damage), or a table {name=, damage=, label=, fluid=true}. GTNH 2.9 AE2 keeps items and fluids
-- in one network; fluid stacks have amount, item stacks size and damage
local M = {}

local craftables = {}   -- key -> {value = craftable or false, at = uptime}

function M.setup(settings)
  M.settings = settings
  craftables = {}
end

local function now()
  return require("computer").uptime()
end

---The ME component: the one at settings.address (or a given address), else the first interface or controller
---@param address string|nil
---@return table|nil proxy
---@return string|nil problem
function M.find(address)
  local component = require("component")
  address = address or (M.settings and M.settings.address) or ""

  if address ~= "" then
    for _, kind in ipairs({"me_interface", "me_controller"}) do
      local full = component.get(address, kind)

      if full ~= nil then
        return component.proxy(full)
      end
    end

    return nil, "[ae2] no ME interface or controller with address "..address..
      " (run: components me_interface, the adapter may have a new address)"
  end

  for _, kind in ipairs({"me_interface", "me_controller"}) do
    local full = component.list(kind)()

    if full ~= nil then
      return component.proxy(full)
    end
  end

  return nil, "[ae2] no ME interface or controller (an adapter touching one, on the computer's cable?)"
end

---What a key or table means: {fluid = bool, name, damage, label}
---@param what string|table
---@return table spec
function M.spec(what)
  if type(what) == "table" then
    return {fluid = what.fluid == true, name = what.name, damage = what.damage, label = what.label}
  end

  assert(type(what) == "string", "[ae2] name what you want as a string or a table")

  local fluid = what:match("^fluid:(.+)$")

  if fluid ~= nil then
    return {fluid = true, name = fluid}
  end

  local name, damage = what:match("^(.+):(%d+)$")

  if name ~= nil and name:find(":") then
    return {fluid = false, name = name, damage = tonumber(damage)}
  end

  return {fluid = false, name = what}
end

---The key of a stack from the network, the same form M.spec reads
---@param stack table
---@return string
function M.key(stack)
  if stack.amount ~= nil and stack.size == nil then
    return "fluid:"..tostring(stack.name)
  end

  if stack.damage ~= nil and stack.damage ~= 0 then
    return tostring(stack.name)..":"..stack.damage
  end

  return tostring(stack.name)
end

local function matches(stack, spec)
  return (spec.name == nil or stack.name == spec.name)
    and (spec.damage == nil or (stack.damage or 0) == spec.damage)
    and (spec.label == nil or stack.label == spec.label)
end

---Every fluid in the network: name -> {name, label, amount}
---@param proxy table
---@return table
function M.fluids(proxy)
  local list, all = proxy.getFluidsInNetwork() or {}, {}

  for _, fluid in ipairs(list) do
    if fluid.name ~= nil then
      all[fluid.name] = {name = fluid.name, label = fluid.label or fluid.name, amount = fluid.amount or 0}
    end
  end

  return all
end

---Items matching a filter ({name=, damage=, label=}, the network filters on its side), each
---{key, name, damage, label, size, craftable}
---@param proxy table
---@param filter table|nil
---@return table[]
function M.items(proxy, filter)
  local list, all = proxy.getItemsInNetwork(filter) or {}, {}

  for _, stack in ipairs(list) do
    if type(stack) == "table" and (stack.name ~= nil or stack.label ~= nil) then
      all[#all + 1] = {key = M.key(stack), name = stack.name, damage = stack.damage or 0,
        label = stack.label or stack.name, size = stack.size or 0, craftable = stack.isCraftable == true}
    end
  end

  return all
end

---How much of something is in the network (0 when none)
---@param proxy table
---@param what string|table
---@return number amount
---@return string|nil label
function M.stock(proxy, what)
  local spec = M.spec(what)

  if spec.fluid then
    local fluid = M.fluids(proxy)[spec.name]
    return fluid and fluid.amount or 0, fluid and fluid.label
  end

  local filter = {name = spec.name, damage = spec.damage, label = spec.label}
  local total, label = 0, nil

  for _, stack in ipairs(M.items(proxy, filter)) do
    if matches(stack, spec) then
      total, label = total + stack.size, label or stack.label
    end
  end

  return total, label
end

---The craftable (recipe) for something, cached for craftableCacheSeconds, nil when not craftable
---@param proxy table
---@param what string|table
---@return table|nil craftable
function M.craftable(proxy, what)
  local spec = M.spec(what)
  local key = (spec.fluid and "fluid:" or "")..tostring(spec.name)..":"..tostring(spec.damage)..":"..tostring(spec.label)
  local cached = craftables[key]
  local keep = M.settings and M.settings.craftableCacheSeconds or 600

  if cached ~= nil and now() - cached.at < keep then
    return cached.value or nil
  end

  local filter = spec.fluid and {name = spec.name} or {name = spec.name, damage = spec.damage, label = spec.label}
  local found = false

  for _, craftable in ipairs(proxy.getCraftables(filter) or {}) do
    local isOk, stack = pcall(craftable.getStack or craftable.getItemStack)

    if isOk and type(stack) == "table" and matches(stack, spec) then
      found = craftable
      break
    end
  end

  craftables[key] = {value = found, at = now()}
  return found or nil
end

---Forget cached craftables (after adding patterns)
function M.forget()
  craftables = {}
end

---Ask the network to craft. Returns the job, or nil and why
---@param proxy table
---@param what string|table
---@param amount number
---@param cpuName string|nil
---@return table|nil job
---@return string|nil problem
function M.request(proxy, what, amount, cpuName)
  local craftable = M.craftable(proxy, what)

  if craftable == nil then
    return nil, "[ae2] no pattern for "..(type(what) == "string" and what or tostring(what.name or what.label))
  end

  local isOk, job = pcall(craftable.request, amount, false, cpuName)

  if not isOk or job == nil then
    return nil, "[ae2] request failed: "..tostring(job)
  end

  return job
end

---State of a job from M.request: "computing", "running", "done", "failed" (with why) or "canceled"
---@param job table
---@return string state
---@return string|nil why
function M.jobState(job)
  local function ask(name)
    if job[name] == nil then
      return false
    end

    local isOk, value, why = pcall(job[name])
    return isOk and value == true, why
  end

  local failed, why = ask("hasFailed")

  if failed then
    return "failed", why
  elseif ask("isCanceled") then
    return "canceled"
  elseif ask("isDone") then
    return "done"
  elseif ask("isComputing") then
    return "computing"
  end

  return "running"
end

---Power of the network in AE: {stored, max, fraction, usage, injection, idle}
---@param proxy table
---@return table
function M.power(proxy)
  local function read(name)
    local isOk, value = pcall(proxy[name])
    return isOk and tonumber(value) or 0
  end

  local stored, max = read("getStoredPower"), read("getMaxStoredPower")

  return {stored = stored, max = max, fraction = max > 0 and stored / max or 0,
    usage = read("getAvgPowerUsage"), injection = read("getAvgPowerInjection"), idle = read("getIdlePowerUsage")}
end

---Crafting CPUs: {name, storage, coprocessors, busy, cpu} (cpu has finalOutput, activeItems, cancel...)
---@param proxy table
---@return table[]
function M.cpus(proxy)
  local all = {}

  for index, cpu in ipairs(proxy.getCpus() or {}) do
    local name = cpu.name

    if name == nil or name == "" then
      name = "CPU "..index
    end

    all[#all + 1] = {name = name, storage = cpu.storage or 0, coprocessors = cpu.coprocessors or 0,
      busy = cpu.busy == true, cpu = cpu.cpu}
  end

  return all
end

return M
