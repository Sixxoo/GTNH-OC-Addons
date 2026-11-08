-- One computer sees all the others. Every program runs a client that broadcasts its status now and
-- then (name, program, a status word, a few values, its alerts); one computer runs the server, keeps the
-- last status of each and notices when one goes quiet (logs it and pushes central_offline / central_online)
local M = {}

local status, clientTimer, serverTimer, computers = {}, nil, nil, {}

function M.setup(settings)
  M.settings = settings
  status, computers = {}, {}
end

local function network()
  return require("addons.core").load("network")
end

local function now()
  return require("computer").uptime()
end

---Name this computer reports under
function M.name()
  if M.settings.name ~= nil and M.settings.name ~= "" then
    return M.settings.name
  end

  local computer = require("computer")
  local isOk, label = pcall(function () return require("component").proxy(computer.getBootAddress()).getLabel() end)

  if isOk and type(label) == "string" and label ~= "" then
    return label
  end

  return tostring(network().address() or computer.address()):sub(1, 8)
end

-- ---------- client ----------

---Set what the next report says: {program, status = "running"|"error"|..., values = {...}, alerts = {...}}
function M.report(fields)
  for key, value in pairs(fields) do
    status[key] = value
  end
end

---Send the status now
function M.send()
  local copy = {name = M.name(), uptime = math.floor(now())}

  for key, value in pairs(status) do
    copy[key] = value
  end

  return network().broadcast("central_status", copy)
end

---Report every reportSeconds until stopClient()
function M.startClient(fields)
  local event = require("event")
  M.stopClient()
  M.report(fields or {})
  network().open()

  clientTimer = event.timer(M.settings.reportSeconds, function ()
    pcall(M.send)
  end, math.huge)

  pcall(M.send)
end

function M.stopClient()
  if clientTimer ~= nil then
    require("event").cancel(clientTimer)
    clientTimer = nil
    M.report({status = "stopped"})
    pcall(M.send)
  end
end

-- ---------- server ----------

local function check()
  local event = require("event")

  for address, entry in pairs(computers) do
    local online = now() - entry.seen < M.settings.offlineSeconds

    if entry.online and not online then
      entry.online = false
      event.push("log_warning", "[Central] "..entry.name.." is offline")
      event.push("central_offline", address, entry.name)
      event.push("alert_raise", "central:"..address, "warning", entry.name.." is offline")
    end
  end
end

---Collect the reports of all computers until stopServer()
function M.startServer()
  local event = require("event")
  M.stopServer()
  network().open()

  network().on("central_status", function (data, from)
    if type(data) ~= "table" then
      return
    end

    local entry = computers[from]
    local wasOffline = entry ~= nil and not entry.online
    entry = {address = from, name = tostring(data.name or from), data = data, seen = now(), online = true}
    computers[from] = entry

    if wasOffline then
      event.push("log_info", "[Central] "..entry.name.." is back")
      event.push("central_online", from, entry.name)
      event.push("alert_clear", "central:"..from)
    end
  end)

  serverTimer = event.timer(10, function () pcall(check) end, math.huge)
end

function M.stopServer()
  if serverTimer ~= nil then
    require("event").cancel(serverTimer)
    serverTimer = nil
  end

  network().on("central_status", nil)
end

---All computers heard from, by name: {address, name, online, seen (seconds ago), program, status, values, alerts}
function M.computers()
  check()
  local list = {}

  for _, entry in pairs(computers) do
    local data = entry.data or {}
    list[#list + 1] = {address = entry.address, name = entry.name, online = entry.online,
      ago = math.floor(now() - entry.seen), program = data.program, status = data.status,
      values = data.values or {}, alerts = data.alerts or {}, uptime = data.uptime}
  end

  table.sort(list, function (a, b) return a.name < b.name end)
  return list
end

---Forget a computer (e.g. one taken down for good)
function M.forget(address)
  computers[address] = nil
  require("event").push("alert_clear", "central:"..address)
end

return M
