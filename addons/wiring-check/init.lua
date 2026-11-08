-- Checks the wiring before a program runs: every component the config names is there. For a missing one
-- it lists the components of that type nobody in the list uses, so a replaced adapter (new address) is
-- found at once: "ME Interface 261af9d4 is missing; one unused me_interface: 0604d547". fix() can write the
-- new address into config.lua
local M = {}

function M.setup(settings)
  M.settings = settings
end

---Check a list: {{name = "ME Interface", type = "me_interface", address = "261af9d4..."}, ...}.
---Entries without an address are skipped. Result: {ok, rows = {{name, type, address, found, candidates}}, missing}
function M.check(list)
  local component = require("component")
  local rows, used, missing = {}, {}, 0

  for _, entry in ipairs(list) do
    if entry.address ~= nil and entry.address ~= "" then
      local found = component.get(entry.address, entry.type)
      rows[#rows + 1] = {name = entry.name or entry.type, type = entry.type, address = entry.address, found = found}

      if found ~= nil then
        used[found] = true
      end
    end
  end

  for _, row in ipairs(rows) do
    if row.found == nil then
      missing = missing + 1
      row.candidates = {}

      for address in component.list(row.type) do
        if not used[address] then
          row.candidates[#row.candidates + 1] = address
        end
      end

      table.sort(row.candidates)
    end
  end

  return {ok = missing == 0, rows = rows, missing = missing}
end

local function short(address)
  return tostring(address):sub(1, 8)
end

---What is wrong, one line per missing component (empty when everything is there)
function M.problems(result)
  local lines = {}

  for _, row in ipairs(result.rows) do
    if row.found == nil then
      local line = row.name.." ("..row.type.." "..short(row.address)..") is missing"
      local count = #row.candidates

      if count == 1 then
        line = line.."; one unused "..row.type..": "..row.candidates[1]..", is that it?"
      elseif count > 1 then
        local names = {}
        for i = 1, math.min(3, count) do names[i] = short(row.candidates[i]) end
        line = line.."; unused "..row.type..": "..table.concat(names, ", ")..(count > 3 and "..." or "")
      else
        line = line.."; no "..row.type.." on the network (cable, adapter, MFU link?)"
      end

      lines[#lines + 1] = line
    end
  end

  return lines
end

---Replace an address in a config file (the whole quoted address). Returns true when it was replaced
function M.fix(path, old, new)
  local file = io.open(path, "r")

  if file == nil then
    return false
  end

  local text = file:read("*a")
  file:close()

  local escaped = old:gsub("%p", "%%%0")
  local changed, count = text:gsub('"'..escaped..'"', '"'..new..'"')

  if count == 0 then
    return false
  end

  file = io.open(path, "w")

  if file == nil then
    return false
  end

  file:write(changed)
  file:close()
  return true
end

---Check and, for each missing component with exactly one unused one of its type, offer to write it into
---the config (ask(question) returns true for yes). Returns the result after the fixes
function M.repair(list, path, ask)
  local result = M.check(list)

  for _, row in ipairs(result.rows) do
    if row.found == nil and #row.candidates == 1 then
      local question = row.name.." "..short(row.address).." is missing. Use the unused "..row.type.." "..
        short(row.candidates[1]).." instead?"

      if ask(question) and M.fix(path, row.address, row.candidates[1]) then
        for _, entry in ipairs(list) do
          if entry.address == row.address then entry.address = row.candidates[1] end
        end

        require("event").push("log_info", "[Wiring] "..row.name.." now "..row.candidates[1])
      end
    end
  end

  return M.check(list)
end

---Every component on the network by type: {type = {address, ...}}, for a check command
function M.inventory()
  local component = require("component")
  local all = {}

  for address, kind in component.list() do
    all[kind] = all[kind] or {}
    table.insert(all[kind], address)
  end

  for _, list in pairs(all) do
    table.sort(list)
  end

  return all
end

return M
