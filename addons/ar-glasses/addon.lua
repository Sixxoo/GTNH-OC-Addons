return {
  name = "ar-glasses",
  version = "1.0.0",
  description = "Text and bars on the HUD of AR glasses (OpenGlasses glasses terminal), kept up to date by key",
  requires = {},
  components = {"glasses"},
  settings = {
    x = {default = 4, description = "Left edge of the HUD lines, in HUD pixels"},
    y = {default = 4, description = "Top edge of the HUD lines, in HUD pixels"},
    lineHeight = {default = 10, description = "Pixels between HUD lines"},
    scale = {default = 1, description = "Text size"},
    background = {default = 0.4, description = "Opacity of the box behind the lines (0 = none)"},
  },
}
