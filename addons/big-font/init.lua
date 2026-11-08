-- Big text, five rows high, drawn with full blocks on a neon-ui canvas. Digits, A-Z (lower case is drawn
-- upper case) and . , : % + - / ! ? and space. Unknown characters are drawn as a space
local M = {}

M.height = 5

local glyphs = {
  ["0"] = {"###", "# #", "# #", "# #", "###"}, ["1"] = {" # ", "## ", " # ", " # ", "###"},
  ["2"] = {"###", "  #", "###", "#  ", "###"}, ["3"] = {"###", "  #", " ##", "  #", "###"},
  ["4"] = {"# #", "# #", "###", "  #", "  #"}, ["5"] = {"###", "#  ", "###", "  #", "###"},
  ["6"] = {"###", "#  ", "###", "# #", "###"}, ["7"] = {"###", "  #", "  #", " # ", " # "},
  ["8"] = {"###", "# #", "###", "# #", "###"}, ["9"] = {"###", "# #", "###", "  #", "###"},
  A = {" # ", "# #", "###", "# #", "# #"}, B = {"## ", "# #", "## ", "# #", "## "},
  C = {"###", "#  ", "#  ", "#  ", "###"}, D = {"## ", "# #", "# #", "# #", "## "},
  E = {"###", "#  ", "## ", "#  ", "###"}, F = {"###", "#  ", "## ", "#  ", "#  "},
  G = {"###", "#  ", "# #", "# #", "###"}, H = {"# #", "# #", "###", "# #", "# #"},
  I = {"###", " # ", " # ", " # ", "###"}, J = {"  #", "  #", "  #", "# #", "###"},
  K = {"# #", "# #", "## ", "# #", "# #"}, L = {"#  ", "#  ", "#  ", "#  ", "###"},
  M = {"#   #", "## ##", "# # #", "#   #", "#   #"}, N = {"#  #", "## #", "# ##", "#  #", "#  #"},
  O = {"###", "# #", "# #", "# #", "###"}, P = {"###", "# #", "###", "#  ", "#  "},
  Q = {"### ", "# # ", "# # ", "### ", "  ##"}, R = {"## ", "# #", "## ", "# #", "# #"},
  S = {"###", "#  ", "###", "  #", "###"}, T = {"###", " # ", " # ", " # ", " # "},
  U = {"# #", "# #", "# #", "# #", "###"}, V = {"# #", "# #", "# #", "# #", " # "},
  W = {"#   #", "#   #", "# # #", "## ##", "#   #"}, X = {"# #", "# #", " # ", "# #", "# #"},
  Y = {"# #", "# #", " # ", " # ", " # "}, Z = {"###", "  #", " # ", "#  ", "###"},
  ["."] = {" ", " ", " ", " ", "#"}, [","] = {"  ", "  ", "  ", " #", "# "},
  [":"] = {" ", "#", " ", "#", " "}, ["%"] = {"# #", "  #", " # ", "#  ", "# #"},
  ["+"] = {"   ", " # ", "###", " # ", "   "}, ["-"] = {"   ", "   ", "###", "   ", "   "},
  ["/"] = {"  #", "  #", " # ", "#  ", "#  "}, ["!"] = {"#", "#", "#", " ", "#"},
  ["?"] = {"###", "  #", " ##", "   ", " # "}, [" "] = {"  ", "  ", "  ", "  ", "  "},
}

function M.setup(settings)
  M.settings = settings
end

local function glyph(char)
  return glyphs[char] or glyphs[char:upper()] or glyphs[" "]
end

local function chars(text)
  return require("addons.core").load("neon-ui").split(tostring(text))
end

---Width of text in cells (one empty column between letters)
function M.width(text)
  local width = 0

  for i, char in ipairs(chars(text)) do
    width = width + #glyph(char)[1] + (i > 1 and 1 or 0)
  end

  return width
end

---Draw big text. Returns its width
---@param bg number|nil Background (nil keeps what is there)
function M.draw(cv, x, y, text, color, bg)
  local fill = M.settings and M.settings.char or "█"
  color = color or require("addons.core").load("neon-ui").colors.text

  for _, char in ipairs(chars(text)) do
    local rows = glyph(char)

    for r = 1, 5 do
      local line = rows[r]

      for c = 1, #line do
        if line:sub(c, c) == "#" then
          cv:put(x + c - 1, y + r - 1, fill, color, bg)
        end
      end
    end

    x = x + #rows[1] + 1
  end

  return M.width(text)
end

---Draw big text centred in a width
function M.center(cv, x, y, w, text, color, bg)
  return M.draw(cv, x + math.floor((w - M.width(text)) / 2), y, text, color, bg)
end

return M
