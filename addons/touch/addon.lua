return {
  name = "touch",
  version = "1.0.0",
  description = "Buttons and touch areas on the screen: draw a neon button, know which one was touched",
  requires = {"neon-ui@1"},
  components = {"screen"},
  settings = {
    repeatSeconds = {default = 0.3, description = "A second touch on the same button within this time is ignored (a double tap is one press)"},
  },
}
