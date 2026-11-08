return {
  name = "alerts",
  version = "1.0.0",
  description = "Problems that need you, in one list until fixed: logged once, a count for the screen, a redstone lamp or siren",
  requires = {},
  components = {},
  settings = {
    redstoneSide = {default = "", description = 'Side of a redstone card or Redstone I/O that is on while an alert is active ("" = none), e.g. "top"'},
    redstoneLevel = {default = "warning", description = 'Lowest level that turns the redstone on: "warning" or "critical"'},
  },
}
