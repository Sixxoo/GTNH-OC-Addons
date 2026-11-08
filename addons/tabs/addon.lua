return {
  name = "tabs",
  version = "1.0.0",
  description = "Pages on one screen: a neon tab row, switched with Tab, arrows, number keys or a touch",
  requires = {"neon-ui@1"},
  components = {},
  settings = {
    arrows = {default = true, description = "Left and right arrows switch tabs"},
    numbers = {default = true, description = "Number keys 1-9 open a tab"},
  },
}
