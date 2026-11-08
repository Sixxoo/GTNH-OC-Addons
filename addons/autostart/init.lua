-- Start a program when the computer boots (OpenOS runs /home/.shrc when its shell starts), and turn
-- the computer on by redstone after a power loss (redstone card wake threshold)
local M = {}

local marker = "# autostart"

function M.setup(settings)
  M.settings = settings
end

local function read(path)
  local file = io.open(path, "r")

  if file == nil then
    return ""
  end

  local text = file:read("*a")
  file:close()
  return text
end

local function write(path, text)
  local file = io.open(path, "w")

  if file == nil then
    error("[autostart] can't write "..path)
  end

  file:write(text)
  file:close()
end

---The command that starts at boot, or nil
---@return string|nil folder
---@return string|nil command
function M.current()
  for line in (read(M.settings.shrc).."\n"):gmatch("(.-)\r?\n") do
    local folder, command = line:match("^cd (%S+) && (.-) "..marker.."$")

    if folder ~= nil then
      return folder, command
    end
  end

  return nil
end

---Start a program at boot, replacing the program that started before. One program only: it runs in the shell
---@param folder string e.g. "/home/water-line"
---@param command string e.g. "main"
function M.enable(folder, command)
  M.disable()
  local text = read(M.settings.shrc)

  if text ~= "" and not text:find("\n$") then
    text = text.."\n"
  end

  write(M.settings.shrc, text.."cd "..folder.." && "..command.." "..marker.."\n")
end

---Nothing starts at boot any more. Other lines in .shrc stay
function M.disable()
  local kept = {}

  for line in (read(M.settings.shrc).."\n"):gmatch("(.-)\r?\n") do
    if not line:find(marker, 1, true) then
      kept[#kept + 1] = line
    end
  end

  while kept[#kept] == "" do
    table.remove(kept)
  end

  write(M.settings.shrc, #kept > 0 and (table.concat(kept, "\n").."\n") or "")
end

---The computer's own redstone card. A Redstone I/O block can't wake a computer
---@return table|nil
function M.redstoneCard()
  local component = require("component")

  for address in component.list("redstone") do
    local isOk, slot = pcall(component.slot or function () return -1 end, address)

    if isOk and type(slot) == "number" and slot >= 0 then
      return component.proxy(address)
    end
  end

  return nil
end

---Whether a redstone signal turns the computer on
---@return boolean|nil nil without a redstone card
function M.wakeIsOn()
  local card = M.redstoneCard()

  if card == nil then
    return nil
  end

  return card.getWakeThreshold() > 0
end

---A rising redstone signal turns the computer on. Wire a slow clock (a pulse every 30 to 60 s) to it
---@return boolean # false without a redstone card
function M.enableWake()
  local card = M.redstoneCard()

  if card == nil then
    return false
  end

  card.setWakeThreshold(1)
  return true
end

function M.disableWake()
  local card = M.redstoneCard()

  if card ~= nil then
    card.setWakeThreshold(0)
  end
end

return M
