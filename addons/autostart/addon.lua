return {
  name = "autostart",
  version = "1.0.0",
  description = "Starts a program when the computer boots, and wakes the computer by redstone after a power loss",
  requires = {},
  components = {"redstone"},
  settings = {
    shrc = {default = "/home/.shrc", description = "File the OpenOS shell runs when it starts"},
  },
}
