-- Messages between OpenComputers over a network card (wired or wireless) or a linked card. A message
-- has a kind ("status", "command"...) and data (numbers, strings, booleans and tables of them). on(kind)
-- handles a kind; what the handler returns goes back as the answer when the sender used request()
local M = {}

local TAG = "gtnh-oc"
local handlers, listener, nextId = {}, nil, 1

function M.setup(settings)
  M.settings = settings
  handlers = {}
end

local function serialize(value, depth)
  depth = depth or 0
  local kind = type(value)

  if kind == "number" then
    return value == math.floor(value) and string.format("%d", value) or string.format("%.10g", value)
  elseif kind == "string" then
    return string.format("%q", value)
  elseif kind == "boolean" then
    return tostring(value)
  elseif kind ~= "table" or depth > 10 then
    return "nil"
  end

  local parts = {}

  for key, item in pairs(value) do
    local name = type(key) == "string" and key:match("^[%a_][%w_]*$") and key or ("["..serialize(key, depth + 1).."]")
    parts[#parts + 1] = name.."="..serialize(item, depth + 1)
  end

  return "{"..table.concat(parts, ",").."}"
end

local function deserialize(text)
  local chunk = type(text) == "string" and load("return "..text, "=message", "t", {}) or nil

  if chunk == nil then
    return nil
  end

  local isOk, value = pcall(chunk)
  return isOk and value or nil
end

M.serialize, M.deserialize = serialize, deserialize

---The card: a network card (modem) or a linked card (tunnel), or nil and why
function M.card()
  local component = require("component")

  for _, kind in ipairs({"modem", "tunnel"}) do
    local address = component.list(kind)()

    if address ~= nil then
      return component.proxy(address), kind
    end
  end

  return nil, "[network] no network card or linked card"
end

---This computer's address on the network (its card's address)
function M.address()
  local card = M.card()
  return card and card.address or nil
end

local function transmit(to, kind, data, id, replyTo)
  local card, cardKind = M.card()

  if card == nil then
    return false
  end

  local payload = serialize(data)

  if cardKind == "tunnel" then
    return card.send(TAG, kind, payload, id, replyTo)
  elseif to == nil then
    return card.broadcast(M.settings.port, TAG, kind, payload, id, replyTo)
  end

  return card.send(to, M.settings.port, TAG, kind, payload, id, replyTo)
end

---Open the port and handle messages until close()
function M.open()
  local event = require("event")
  local card, kind = M.card()
  assert(card ~= nil, kind)

  if kind == "modem" then
    card.open(M.settings.port)
  end

  if listener ~= nil then
    event.cancel(listener)
  end

  listener = event.listen("modem_message", function (_, _, from, port, distance, tag, messageKind, payload, id, replyTo)
    if tag ~= TAG or (kind == "modem" and port ~= M.settings.port) then
      return
    end

    if replyTo ~= nil then
      event.push("network_reply", replyTo, payload, from)
      return
    end

    local handler = handlers[messageKind]

    if handler == nil then
      return
    end

    local isOk, answer = pcall(handler, deserialize(payload), from, distance)

    if not isOk then
      event.push("log_error", "[Network] "..tostring(messageKind)..": "..tostring(answer))
      answer = {error = tostring(answer)}
    end

    if id ~= nil then
      transmit(from, messageKind, answer, nil, id)
    end
  end)

  return true
end

---Handle a kind of message: handler(data, from, distance) -> answer (sent back for request())
function M.on(kind, handler)
  handlers[kind] = handler
end

---Send to one computer (its card address)
function M.send(to, kind, data)
  return transmit(to, kind, data)
end

---Send to every computer in range on the port
function M.broadcast(kind, data)
  return transmit(nil, kind, data)
end

---Send and wait for the answer: data, or nil and "timeout"
function M.request(to, kind, data, timeout)
  local event = require("event")
  local id = tostring(nextId).."-"..tostring(math.random(1, 1e6))
  nextId = nextId + 1
  transmit(to, kind, data, id)

  local _, _, payload, from = event.pullFiltered(timeout or M.settings.timeoutSeconds, function (name, replyTo)
    return name == "network_reply" and replyTo == id
  end)

  if from == nil then
    return nil, "timeout"
  end

  return deserialize(payload), from
end

---Stop handling messages and close the port
function M.close()
  local event = require("event")

  if listener ~= nil then
    event.cancel(listener)
    listener = nil
  end

  local card, kind = M.card()

  if card ~= nil and kind == "modem" then
    pcall(card.close, M.settings.port)
  end
end

return M
