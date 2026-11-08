-- Commands a program offers to other computers over the network: command("status", handler, "what it does").
-- Only computers in allowFrom may run them (nobody by default). call() runs a command on another computer
-- and returns its answer. "help" lists the commands of a computer
local M = {}

local commands = {}

function M.setup(settings)
  M.settings = settings
  commands = {}
end

local function network()
  return require("addons.core").load("network")
end

---Offer a command: handler(args, from) returns the answer (numbers, strings, tables)
function M.command(name, handler, description)
  commands[name] = {handler = handler, description = description or ""}
end

---Is a computer allowed to send commands?
function M.allowed(from)
  for _, allowed in ipairs(M.settings.allowFrom or {}) do
    if allowed == "*" or (type(from) == "string" and from:sub(1, #allowed) == allowed) then
      return true
    end
  end

  return false
end

---Answer commands from allowed computers until stop()
function M.start()
  local event = require("event")
  network().open()

  network().on("remote_command", function (data, from)
    if not M.allowed(from) then
      event.push("log_warning", "[Remote] Refused a command from "..tostring(from):sub(1, 8).." (not in allowFrom)")
      return {ok = false, error = "not allowed"}
    end

    if type(data) ~= "table" or type(data.name) ~= "string" then
      return {ok = false, error = "bad command"}
    end

    if data.name == "help" then
      local list = {}
      for name, entry in pairs(commands) do list[name] = entry.description end
      return {ok = true, result = list}
    end

    local entry = commands[data.name]

    if entry == nil then
      return {ok = false, error = "no command "..data.name}
    end

    event.push("log_info", "[Remote] "..data.name.." from "..tostring(from):sub(1, 8))
    local isOk, result = pcall(entry.handler, data.args or {}, from)

    if not isOk then
      return {ok = false, error = tostring(result)}
    end

    return {ok = true, result = result}
  end)
end

function M.stop()
  network().on("remote_command", nil)
end

---Run a command on another computer: its answer, or nil and why
function M.call(to, name, args, timeout)
  local answer, problem = network().request(to, "remote_command", {name = name, args = args}, timeout)

  if answer == nil then
    return nil, problem
  elseif type(answer) ~= "table" then
    return nil, "bad answer"
  elseif not answer.ok then
    return nil, answer.error
  end

  return answer.result
end

---The commands of another computer: {name = description}
function M.help(to, timeout)
  return M.call(to, "help", nil, timeout)
end

return M
