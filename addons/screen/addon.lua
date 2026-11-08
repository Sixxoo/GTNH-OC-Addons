return {
  name = "screen",
  version = "1.0.0",
  description = "Shows frames of coloured lines without flicker, fits the resolution to the screen's shape",
  requires = {},
  components = {"gpu", "screen"},
  settings = {
    rows = {default = 35, description = "Rows used on the screen; the width follows from the screen's shape"},
    minWidth = {default = 80, description = "Narrowest width in characters"},
    fullRedrawSeconds = {default = 60, description = "Seconds between frames that draw every row, not only changed ones"},
  },
}
