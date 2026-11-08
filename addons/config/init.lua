-- Program settings: a schema says what each setting may be, check() lists every problem with the
-- setting's path, load() reads a config file safely, edit() opens it in the editor and checks it again,
-- merge() carries the player's values into the config file of a new version
local M = {}

M.merger = require("addons.config.merge")

function M.setup(settings)
  M.settings = settings
end

-- ---------- schema ----------

local function field(kind, options)
  options = options or {}
  options.kind = kind
  return options
end

---A number. Options: min, max, integer, optional, default, check
function M.number(options) return field("number", options) end
---A string. Options: nonEmpty, pattern, optional, default, check
function M.string(options) return field("string", options) end
---true or false. Options: optional, default
function M.boolean(options) return field("boolean", options) end
---One of the values, any letter case. Options: optional, default
function M.enum(values, options) options = options or {} options.values = values return field("enum", options) end
---A component address like "1a2b3c4d-...". Options: optional, default
function M.address(options) return field("address", options) end
---A side: "up", "down", "north", "south", "west", "east" or 0-5; becomes the number
function M.side(options) return field("side", options) end
---A colour 0xRRGGBB
function M.color(options) return field("color", options) end
---A table with known fields: M.table({name = M.string(), ...}, options)
function M.table(fields, options) options = options or {} options.fields = fields return field("table", options) end
---A list of values of one kind. Options: min (fewest items)
function M.list(item, options) options = options or {} options.item = item return field("list", options) end
---A table whose keys are free and whose values are of one kind
function M.map(value, options) options = options or {} options.value = value return field("map", options) end

local sideNames = {down = 0, bottom = 0, up = 1, top = 1, north = 2, south = 3, west = 4, east = 5}
local uuid = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"

local function show(value)
  if type(value) == "string" then
    return string.format("%q", value)
  end

  return tostring(value)
end

local check

---@return any value The value as the program uses it (defaults filled, enums and sides normalised)
local function checkValue(value, schema, path, root, problems, warnings)
  if value == nil then
    if schema.default ~= nil then
      return schema.default
    end

    if not schema.optional then
      table.insert(problems, path..": missing")
    end

    return nil
  end

  local kind = schema.kind
  local function bad(message)
    table.insert(problems, path..": "..message)
  end

  if kind == "number" or kind == "color" then
    if type(value) ~= "number" then
      bad("must be a number, is "..show(value))
      return value
    end

    if kind == "color" and (value < 0 or value > 0xFFFFFF or value % 1 ~= 0) then
      bad("must be a colour like 0x00B4FF")
    end

    if schema.integer and value % 1 ~= 0 then bad("must be a whole number") end
    if schema.min and value < schema.min then bad("must be at least "..schema.min..", is "..value) end
    if schema.max and value > schema.max then bad("must be at most "..schema.max..", is "..value) end
  elseif kind == "string" then
    if type(value) ~= "string" then
      bad("must be text in quotes, is "..show(value))
      return value
    end

    if schema.nonEmpty and value == "" then bad("must not be empty") end
    if schema.pattern and value ~= "" and not value:match(schema.pattern) then bad("has the wrong form: "..show(value)) end
  elseif kind == "boolean" then
    if type(value) ~= "boolean" then bad("must be true or false, is "..show(value)) end
  elseif kind == "enum" then
    if type(value) == "string" then
      for _, allowed in ipairs(schema.values) do
        if value:lower() == allowed:lower() then
          return allowed
        end
      end
    end

    local names = {}
    for _, allowed in ipairs(schema.values) do names[#names + 1] = show(allowed) end
    bad("is "..show(value)..", use one of: "..table.concat(names, ", "))
  elseif kind == "address" then
    if type(value) ~= "string" or not value:lower():match(uuid) then
      bad("must be a full address like \"1a2b3c4d-1a2b-1a2b-1a2b-1a2b3c4d5e6f\" (Analyzer, click the chat line), is "..show(value))
    end
  elseif kind == "side" then
    if type(value) == "string" and sideNames[value:lower()] ~= nil then
      return sideNames[value:lower()]
    end

    if type(value) == "number" and value >= 0 and value <= 5 and value % 1 == 0 then
      return value
    end

    bad("is "..show(value)..', use "up", "down", "north", "south", "west", "east" or 0-5')
  elseif kind == "table" then
    if type(value) ~= "table" then
      bad("must be a table { ... }, is "..show(value))
      return value
    end

    local result = {}

    for key, child in pairs(schema.fields) do
      result[key] = checkValue(value[key], child, path == "" and key or (path.."."..key), root, problems, warnings)
    end

    for key in pairs(value) do
      if schema.fields[key] == nil then
        table.insert(warnings, (path == "" and tostring(key) or (path.."."..tostring(key)))..": unknown setting, ignored")
      end
    end

    value = result
  elseif kind == "list" then
    if type(value) ~= "table" then
      bad("must be a list { ... }, is "..show(value))
      return value
    end

    local result = {}

    for index, item in ipairs(value) do
      result[index] = checkValue(item, schema.item, path.."["..index.."]", root, problems, warnings)
    end

    if schema.min and #value < schema.min then bad("needs at least "..schema.min.." items") end
    value = result
  elseif kind == "map" then
    if type(value) ~= "table" then
      bad("must be a table { ... }, is "..show(value))
      return value
    end

    local result = {}

    for key, item in pairs(value) do
      result[key] = checkValue(item, schema.value, path.."."..tostring(key), root, problems, warnings)
    end

    value = result
  end

  if schema.check ~= nil and #problems == 0 then
    local isOk, message = schema.check(value, root)

    if isOk == false then
      bad(message or "is not allowed")
    end
  end

  return value
end

---Check a value against a schema
---@param value any
---@param schema table From M.table(...) etc.
---@return any config The value with defaults filled and enums and sides normalised
---@return string[] problems Each "path.to.setting: what is wrong"; empty when it is fine
---@return string[] warnings Unknown settings, ignored
function M.check(value, schema)
  local problems, warnings = {}, {}
  local result = checkValue(value, schema, "", value, problems, warnings)
  table.sort(problems)
  table.sort(warnings)
  return result, problems, warnings
end
check = M.check

-- ---------- files ----------

---Read a config file without letting it reach the computer
---@param path string
---@return table|nil value
---@return string|nil problem
function M.read(path)
  local file = io.open(path, "r")

  if file == nil then
    return nil, path.." is missing"
  end

  local text = file:read("*a")
  file:close()

  return M.merger.load(text)
end

---Read and check a config file. Errors list every problem
---@param path string
---@param schema table
---@return table config
---@return string[] warnings
function M.load(path, schema)
  local value, problem = M.read(path)

  if value == nil then
    error("[config] "..tostring(problem), 0)
  end

  local config, problems, warnings = check(value, schema)

  if #problems > 0 then
    error("[config] "..path.." has mistakes:\n  "..table.concat(problems, "\n  "), 0)
  end

  return config, warnings
end

---Open the config file in the OpenOS editor, then check it
---@param path string
---@param schema table
---@return table|nil config nil when the file has mistakes
---@return string[] problems
---@return string[] warnings
function M.edit(path, schema)
  require("shell").execute("edit "..path)

  local value, problem = M.read(path)

  if value == nil then
    return nil, {tostring(problem)}, {}
  end

  local config, problems, warnings = check(value, schema)

  if #problems > 0 then
    return nil, problems, warnings
  end

  return config, problems, warnings
end

---Carry the player's values into the config file of a new version. See merge.lua
---@param oldText string
---@param newText string
---@param rules? table {whenMissing = {{pattern, value, why}}, moved = {{from, to}}}
function M.merge(oldText, newText, rules)
  return M.merger.merge(oldText, newText, rules)
end

---Lines that tell the player what a merge did
function M.describe(report)
  return M.merger.describe(report)
end

return M
