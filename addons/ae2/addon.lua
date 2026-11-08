return {
  name = "ae2",
  version = "1.0.0",
  description = "ME network: find it, read items and fluids by one key, power, CPUs, cached craftables, requests",
  requires = {},
  components = {"me_interface", "me_controller"},
  settings = {
    address = {default = "", description = "Address (or its start) of the ME interface or controller; empty takes the first one"},
    craftableCacheSeconds = {default = 600, description = "How long a craftable lookup (also 'not craftable') is kept, lookups are expensive"},
  },
}
