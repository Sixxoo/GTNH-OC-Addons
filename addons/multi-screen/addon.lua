return {
  name = "multi-screen",
  version = "1.0.0",
  description = "Several screens from one computer: each screen its own frame, one GPU per screen or one shared GPU",
  requires = {},
  components = {"gpu", "screen"},
  settings = {
    rows = {default = 25, description = "Rows of a screen without its own rows in open()"},
  },
}
