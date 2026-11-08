-- A fake OpenOS for tests: components, events, timers, a world clock and a GPU that records every cell.
-- It copies the OpenComputers behaviour that surprised us in game, so tests catch those bugs:
--   * listeners outlive the program that made them (they live in one shared table)
--   * transposer: getTankCount gives nil on a side without a tank, getFluidInTank errors on a bad index,
--     an empty tank has no name and no amount
--   * the screen can be unbound from the GPU
--   * os.sleep drops signals that arrive meanwhile (listeners still see them)
local oc = {}

local clock = 0           -- world seconds since the start of the test
local realClockMs = 1762600000000
local queue = {}          -- signals waiting for event.pull
local listeners = {}      -- id -> {name, callback}
local timers = {}         -- id -> {due, interval, times, callback}
local nextId = 1
local componentsByAddress = {}

oc.log = {}               -- errors from listeners and timers (OpenOS writes them to /tmp/event.log)

-- ---------- time ----------

local function runTimers()
  local ran = true

  while ran do
    ran = false

    for id, timer in pairs(timers) do
      if timer.due <= clock then
        ran = true
        timer.times = timer.times - 1

        if timer.times <= 0 then
          timers[id] = nil
        else
          timer.due = timer.due + timer.interval
        end

        local isOk, problem = pcall(timer.callback)

        if not isOk then
          table.insert(oc.log, "timer: "..tostring(problem))
        end
      end
    end
  end
end

---Let world time pass: timers run, os.sleep inside them does not nest
---@param seconds number
function oc.advance(seconds)
  local target = clock + seconds
  realClockMs = realClockMs + math.floor(seconds * 1000)

  while true do
    local nextDue = nil

    for _, timer in pairs(timers) do
      if timer.due <= target and (nextDue == nil or timer.due < nextDue) then
        nextDue = timer.due
      end
    end

    if nextDue == nil then
      break
    end

    clock = math.max(clock, nextDue)
    runTimers()
  end

  clock = target
end

function oc.now()
  return clock
end

-- ---------- event ----------

local event = {}

function event.listen(name, callback)
  local id = nextId
  nextId = nextId + 1
  listeners[id] = {name = name, callback = callback}
  return id
end

function event.ignore(name, callback)
  for id, listener in pairs(listeners) do
    if listener.name == name and listener.callback == callback then
      listeners[id] = nil
      return true
    end
  end

  return false
end

function event.timer(interval, callback, times)
  local id = nextId
  nextId = nextId + 1
  timers[id] = {due = clock + interval, interval = interval, times = times or 1, callback = callback}
  return id
end

function event.cancel(id)
  local found = listeners[id] ~= nil or timers[id] ~= nil
  listeners[id] = nil
  timers[id] = nil
  return found
end

---Deliver a signal: listeners first, then it waits for event.pull
function event.push(name, ...)
  local signal = table.pack(name, ...)

  for _, listener in pairs(listeners) do
    if listener.name == name then
      local isOk, result = pcall(listener.callback, table.unpack(signal, 1, signal.n))

      if not isOk then
        table.insert(oc.log, "listener "..name..": "..tostring(result))
      elseif result == false then
        event.ignore(listener.name, listener.callback)
      end
    end
  end

  table.insert(queue, signal)
  return true
end

---One signal from the queue. Names are Lua patterns, like in OpenOS ("exit" also matches "thread_exit")
function event.pull(timeout, name, ...)
  if type(timeout) == "string" then
    name, timeout = timeout, nil
  end

  for index, signal in ipairs(queue) do
    if name == nil or tostring(signal[1]):match(name) then
      table.remove(queue, index)
      return table.unpack(signal, 1, signal.n)
    end
  end

  if timeout ~= nil then
    oc.advance(timeout)
  end

  return nil
end

function event.pullFiltered(timeout, filter)
  if type(timeout) == "function" then
    filter, timeout = timeout, nil
  end

  for index, signal in ipairs(queue) do
    if filter == nil or filter(table.unpack(signal, 1, signal.n)) then
      table.remove(queue, index)
      return table.unpack(signal, 1, signal.n)
    end
  end

  if timeout ~= nil then
    oc.advance(timeout)
  end

  return nil
end

oc.event = event

---How many listeners and timers are still registered (a program that cleans up leaves 0)
function oc.leftovers()
  local count = 0

  for _ in pairs(listeners) do count = count + 1 end
  for _ in pairs(timers) do count = count + 1 end

  return count
end

-- ---------- components ----------

local component = {}

---Add a fake component
---@param kind string Component type, e.g. "gt_machine"
---@param proxy table Its methods
---@param address? string
---@return string address
function oc.addComponent(kind, proxy, address)
  -- Spread the first characters, so a short prefix finds one component, like real random addresses
  address = address or string.format("%08x-0000-4000-8000-%012x", (nextId * 2654435761) % 4294967296, nextId)
  nextId = nextId + 1
  proxy.address = address
  proxy.type = kind
  componentsByAddress[address] = {type = kind, proxy = proxy}
  event.push("component_added", address, kind)
  return address
end

function oc.removeComponent(address)
  local entry = componentsByAddress[address]
  componentsByAddress[address] = nil

  if entry ~= nil then
    event.push("component_removed", address, entry.type)
  end
end

function component.list(filter, exact)
  local result = {}

  for address, entry in pairs(componentsByAddress) do
    if filter == nil or (exact and entry.type == filter) or (not exact and entry.type:find(filter, 1, true)) then
      result[address] = entry.type
    end
  end

  local key = nil

  return setmetatable(result, {__call = function ()
    key = next(result, key)
    return key, key and result[key]
  end})
end

function component.proxy(address)
  local entry = componentsByAddress[address]

  if entry == nil then
    return nil, "no such component"
  end

  return entry.proxy
end

function component.get(prefix, kind)
  for address, entry in pairs(componentsByAddress) do
    if address:sub(1, #prefix) == prefix and (kind == nil or entry.type == kind) then
      return address
    end
  end

  return nil, "no such component"
end

function component.type(address)
  local entry = componentsByAddress[address]
  return entry and entry.type
end

function component.isAvailable(kind)
  return component.list(kind, true)() ~= nil
end

function component.getPrimary(kind)
  local address = component.list(kind, true)()

  if address == nil then
    error("no primary '"..kind.."' available")
  end

  return componentsByAddress[address].proxy
end

function component.invoke(address, method, ...)
  local entry = componentsByAddress[address]

  if entry == nil then
    error("no such component")
  end

  return entry.proxy[method](...)
end

setmetatable(component, {__index = function (_, kind)
  local address = component.list(kind, true)()
  return address and componentsByAddress[address].proxy
end})

oc.component = component

-- ---------- GPU and screen ----------

---A GPU with a screen that records every cell's character and colours
---@param maxWidth? integer
---@param maxHeight? integer
---@param aspect? integer[] Screen size in blocks {width, height}
function oc.addScreen(maxWidth, maxHeight, aspect)
  maxWidth, maxHeight = maxWidth or 160, maxHeight or 50
  aspect = aspect or {5, 3}

  local function newBuffer(width, height)
    local buffer = {width = width, height = height, cells = {}}

    for y = 1, height do
      buffer.cells[y] = {}

      for x = 1, width do
        buffer.cells[y][x] = {" ", 0xFFFFFF, 0x000000}
      end
    end

    return buffer
  end

  local screenAddress = oc.addComponent("screen", {
    getAspectRatio = function () return aspect[1], aspect[2] end,
    isOn = function () return true end,
  })

  local buffers = {[0] = newBuffer(maxWidth, maxHeight)}
  local active, foreground, background = 0, 0xFFFFFF, 0x000000
  local width, height = maxWidth, maxHeight
  local bound = screenAddress
  local nextBuffer = 1
  local gpu = {}

  function gpu.maxResolution() return maxWidth, maxHeight end
  function gpu.getResolution() return width, height end
  function gpu.setResolution(w, h) width, height = w, h return true end
  function gpu.getScreen() return bound end
  function gpu.bind(address) bound = address buffers[0] = newBuffer(maxWidth, maxHeight) return true end
  function gpu.setForeground(color) local old = foreground foreground = color return old end
  function gpu.setBackground(color) local old = background background = color return old end
  function gpu.getForeground() return foreground end
  function gpu.getBackground() return background end
  function gpu.allocateBuffer(w, h)
    local id = nextBuffer
    nextBuffer = nextBuffer + 1
    buffers[id] = newBuffer(w or width, h or height)
    return id
  end
  function gpu.freeBuffer(id) buffers[id] = nil if active == id then active = 0 end return true end
  function gpu.freeAllBuffers() for id in pairs(buffers) do if id ~= 0 then buffers[id] = nil end end active = 0 end
  function gpu.setActiveBuffer(id) active = id return true end
  function gpu.getActiveBuffer() return active end

  function gpu.set(x, y, text)
    local buffer = buffers[active]
    local column = 0

    for char in tostring(text):gmatch("[%z\1-\127\194-\244][\128-\191]*") do
      local row = buffer.cells[y]

      if row ~= nil and row[x + column] ~= nil then
        row[x + column] = {char, foreground, background}
      end

      column = column + 1
    end

    return true
  end

  function gpu.fill(x, y, w, h, char)
    for row = y, y + h - 1 do
      gpu.set(x, row, string.rep(char, w))
    end

    return true
  end

  function gpu.bitblt(destination, x, y, w, h, source, sourceX, sourceY)
    destination, source = destination or 0, source or active
    local target, from = buffers[destination], buffers[source]
    x, y, sourceX, sourceY = x or 1, y or 1, sourceX or 1, sourceY or 1
    w, h = w or from.width, h or from.height

    for row = 0, h - 1 do
      for column = 0, w - 1 do
        local cell = from.cells[sourceY + row] and from.cells[sourceY + row][sourceX + column]

        if cell ~= nil and target.cells[y + row] ~= nil and target.cells[y + row][x + column] ~= nil then
          target.cells[y + row][x + column] = {cell[1], cell[2], cell[3]}
        end
      end
    end

    return true
  end

  oc.addComponent("gpu", gpu)

  local screen = {address = screenAddress}

  ---Take the screen away from the GPU, like a screen leaving the network
  function screen.unbind()
    bound = nil
  end

  ---What the visible screen shows: lines with colour codes, &&0xRRGGBB; background, &0xRRGGBB; foreground
  function screen.lines()
    local lines = {}
    local visible = buffers[0]

    for y = 1, height do
      local parts, fg, bg = {}, nil, nil

      for x = 1, width do
        local cell = visible.cells[y][x]

        if cell[3] ~= bg then
          bg = cell[3]
          parts[#parts + 1] = string.format("&&0x%06X;", bg)
        end

        if cell[1] ~= " " and cell[2] ~= fg then
          fg = cell[2]
          parts[#parts + 1] = string.format("&0x%06X;", fg)
        end

        parts[#parts + 1] = cell[1]
      end

      lines[y] = table.concat(parts)
    end

    return lines
  end

  ---The visible screen as plain text, one string per row
  function screen.text()
    local rows = {}

    for y = 1, height do
      local chars = {}

      for x = 1, width do
        chars[x] = buffers[0].cells[y][x][1]
      end

      rows[y] = table.concat(chars)
    end

    return rows
  end

  ---Character, foreground and background of one cell
  function screen.cell(x, y)
    local cell = buffers[0].cells[y][x]
    return cell[1], cell[2], cell[3]
  end

  return gpu, screen
end

-- ---------- fake machines ----------

---A GT machine as an adapter shows it
---@param name string e.g. "multimachine.purificationplant"
---@param state? table {work, progress, maxProgress, allowed, sensor}
function oc.gtMachine(name, state)
  state = state or {}
  state.allowed = state.allowed ~= false

  local proxy = {
    getName = function () return name end,
    hasWork = function () return state.work == true end,
    getWorkProgress = function () return state.progress or 0 end,
    getWorkMaxProgress = function () return state.maxProgress or 0 end,
    isWorkAllowed = function () return state.allowed end,
    setWorkAllowed = function (allowed) state.allowed = allowed return true end,
    getSensorInformation = function () return state.sensor or {} end,
  }

  return oc.addComponent("gt_machine", proxy, state.address), state
end

---A transposer. tanks[side] = list of {name, amount, capacity} (an empty tank: {capacity = n}),
---items[side] = list of {label, size, slot}
function oc.transposer(tanks, items, address)
  tanks, items = tanks or {}, items or {}
  local moves = {}

  local proxy = {
    getTankCount = function (side)
      local list = tanks[side]
      return list and #list or nil
    end,
    getFluidInTank = function (side, tank)
      local list = tanks[side]

      if list == nil or list[tank] == nil then
        error("invalid tank index")
      end

      local fluid = list[tank]

      if fluid.name == nil or (fluid.amount or 0) <= 0 then
        return {capacity = fluid.capacity or 0}
      end

      return {name = fluid.name, amount = fluid.amount, capacity = fluid.capacity or fluid.amount}
    end,
    transferFluid = function (from, to, amount, tank)
      local source = tanks[from] and tanks[from][tank or 1]

      if source == nil or source.name == nil then
        return false, 0
      end

      local moved = math.min(amount or source.amount, source.amount)
      source.amount = source.amount - moved
      table.insert(moves, {kind = "fluid", from = from, to = to, amount = moved, name = source.name})

      local target = tanks[to] and tanks[to][1]

      if target ~= nil then
        target.name = source.name
        target.amount = (target.amount or 0) + moved
      end

      return true, moved
    end,
    getInventorySize = function (side)
      return items[side] and 27 or nil
    end,
    getStackInSlot = function (side, slot)
      for _, stack in ipairs(items[side] or {}) do
        if stack.slot == slot then
          return {label = stack.label, size = stack.size, name = stack.name or stack.label}
        end
      end

      return nil
    end,
    transferItem = function (from, to, count, slot)
      for _, stack in ipairs(items[from] or {}) do
        if slot == nil or stack.slot == slot then
          local moved = math.min(count or stack.size, stack.size)
          stack.size = stack.size - moved
          table.insert(moves, {kind = "item", from = from, to = to, amount = moved, label = stack.label})
          return moved
        end
      end

      return 0
    end,
  }

  return oc.addComponent("transposer", proxy, address), moves
end

---An ME interface. fluids / items: name -> amount (items by label)
function oc.meInterface(fluids, items, address)
  fluids, items = fluids or {}, items or {}

  local proxy = {
    getFluidInNetwork = function (name)
      return {name = name, amount = fluids[name] or 0}
    end,
    getFluidsInNetwork = function ()
      local list = {}

      for name, amount in pairs(fluids) do
        table.insert(list, {name = name, amount = amount})
      end

      return list
    end,
    getItemsInNetwork = function (filter)
      local list = {}

      for label, size in pairs(items) do
        if filter == nil or filter.label == nil or filter.label == label then
          table.insert(list, {label = label, size = size, damage = 0})
        end
      end

      return list
    end,
  }

  return oc.addComponent("me_interface", proxy, address), {fluids = fluids, items = items}
end

-- ---------- the rest of OpenOS ----------

local sides = {bottom = 0, down = 0, negy = 0, top = 1, up = 1, posy = 1, back = 2, north = 2, negz = 2,
  front = 3, south = 3, posz = 3, right = 4, west = 4, negx = 4, left = 5, east = 5, posx = 5}

for name, value in pairs(sides) do
  sides[value] = sides[value] or name
end

local unicode = {}

function unicode.len(text)
  local count = 0

  for _ in tostring(text):gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    count = count + 1
  end

  return count
end

unicode.wlen = unicode.len
unicode.char = utf8.char

function unicode.sub(text, first, last)
  local chars = {}

  for char in tostring(text):gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    chars[#chars + 1] = char
  end

  last = last or #chars
  if first < 0 then first = #chars + first + 1 end
  if last < 0 then last = #chars + last + 1 end

  return table.concat(chars, "", math.max(first, 1), math.min(last, #chars))
end

function unicode.charWidth()
  return 1
end

local computer = {
  uptime = function () return clock end,
  address = function () return "00000000-computer" end,
  freeMemory = function () return 1024 * 1024 end,
  totalMemory = function () return 2 * 1024 * 1024 end,
  energy = function () return 10000 end,
  maxEnergy = function () return 10000 end,
  pushSignal = function (...) return event.push(...) end,
  beep = function () end,
}

---Real time in ms, as filesystem.lastModified gives it for a file just written (UTC)
function oc.realTimeMs()
  return realClockMs
end

local term = {
  write = function () end,
  clear = function () end,
  setCursor = function () end,
  getCursor = function () return 1, 1 end,
  setCursorBlink = function () end,
  isAvailable = function () return true end,
  read = function () return "" end,
}

local keyboard = {keys = setmetatable({
  q = 16, e = 18, y = 21, n = 49, up = 200, down = 208, left = 203, right = 205, enter = 28, space = 57,
}, {__index = function (_, key) return key end})}

-- filesystem on the real disk of the test machine; lastModified gives the fake real clock,
-- like OpenComputers does for a file just written
local filesystem = {}

function filesystem.exists(path)
  local file = io.open(path, "r")
  if file then file:close() return true end
  return os.execute('test -e "'..path..'"') == true
end

function filesystem.isDirectory(path)
  return os.execute('test -d "'..path..'"') == true
end

function filesystem.makeDirectory(path)
  return os.execute('mkdir -p "'..path..'"') == true
end

function filesystem.remove(path)
  return os.execute('rm -rf "'..path..'"') == true
end

function filesystem.rename(from, to)
  return os.rename(from, to) == true
end

function filesystem.copy(from, to)
  return os.execute('cp "'..from..'" "'..to..'"') == true
end

function filesystem.size(path)
  local file = io.open(path, "r")
  if file == nil then return 0 end
  local size = file:seek("end")
  file:close()
  return size
end

function filesystem.lastModified()
  return realClockMs
end

oc.filesystem = filesystem

---Put the fake OpenOS into package.loaded. Call once at the start of a test file
function oc.install()
  package.loaded.event = event
  package.loaded.component = component
  package.loaded.computer = computer
  package.loaded.sides = sides
  package.loaded.unicode = unicode
  package.loaded.term = term
  package.loaded.filesystem = filesystem
  package.loaded.keyboard = keyboard
  package.loaded.shell = {execute = function () return true end, setWorkingDirectory = function () end,
    getWorkingDirectory = function () return "/home" end}
  package.loaded.serialization = {serialize = function (value) return tostring(value) end}
  package.loaded.thread = {create = function (callback, ...)
    local routine = coroutine.create(callback)
    coroutine.resume(routine, ...)
    return {status = function () return coroutine.status(routine) end, kill = function () end}
  end}

  os.sleep = function (seconds)
    oc.advance(seconds or 0)
  end
end

return oc
