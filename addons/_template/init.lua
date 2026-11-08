-- Rules (FORMAT.md): no side effects on require, no globals, other addons only through
-- require("addons.<name>") and only those in addon.lua's requires, errors start with "[<name>]"
local M = {}

local listeners = {}

---Called by addons.core with the merged settings
---@param settings table
function M.setup(settings)
  M.settings = settings
end

---Start what keeps running. Keep every id, so stop() can cancel it
function M.start()
end

---Undo everything start() did: in OpenOS listeners outlive the program that made them
function M.stop()
  local event = require("event")

  for _, id in ipairs(listeners) do
    event.cancel(id)
  end

  listeners = {}
end

return M
