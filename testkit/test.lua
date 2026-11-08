-- Small test helpers for testkit/run.py
local t = {}

local results = {passed = 0, failed = {}, snapshots = {}}
local current = nil

local function show(value)
  if type(value) == "string" then
    return string.format("%q", value)
  end

  return tostring(value)
end

local function fail(message, level)
  error({testFailure = true, message = message}, (level or 1) + 1)
end

---Run one test. A failing check stops only this test
---@param name string
---@param body function
function t.test(name, body)
  current = name
  local isOk, problem = xpcall(body, function (err)
    if type(err) == "table" and err.testFailure then
      return err.message
    end

    return debug.traceback(tostring(err), 2)
  end)

  if isOk then
    results.passed = results.passed + 1
  else
    table.insert(results.failed, {name = name, message = tostring(problem)})
  end

  current = nil
end

function t.equal(actual, expected, what)
  if actual ~= expected then
    fail((what and (what..": ") or "").."expected "..show(expected)..", got "..show(actual), 2)
  end
end

function t.truthy(value, what)
  if not value then
    fail((what or "value").." should be true, got "..show(value), 2)
  end
end

function t.falsy(value, what)
  if value then
    fail((what or "value").." should be false, got "..show(value), 2)
  end
end

---Text contains a plain piece of text
function t.contains(text, piece, what)
  if type(text) ~= "string" or not text:find(piece, 1, true) then
    fail((what and (what..": ") or "")..show(text).." should contain "..show(piece), 2)
  end
end

---The function raises an error whose message contains the piece
function t.errors(body, piece)
  local isOk, problem = pcall(body)

  if isOk then
    fail("expected an error"..(piece and (" with "..show(piece)) or ""), 2)
  end

  if piece ~= nil and not tostring(problem):find(piece, 1, true) then
    fail("error "..show(tostring(problem)).." should contain "..show(piece), 2)
  end
end

---Keep a picture of the screen; run.py saves it as testkit/out/<test file>-<name>.png
---@param name string
---@param lines string[] screen.lines() from testkit/oc.lua
function t.snapshot(name, lines)
  results.snapshots[name] = lines
end

---Return this at the end of a test file
function t.finish()
  return results
end

return t
