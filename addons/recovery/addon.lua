return {
  name = "recovery",
  version = "1.1.0",
  description = "Restarts a failing program after a pause, cleans up its listeners, safe state after minutes of errors",
  requires = {},
  components = {},
  settings = {
    retrySeconds = {default = 30, description = "Seconds to wait before starting again after an error"},
    giveUpMinutes = {default = 5, description = "Minutes of failing in a row before the safe state and stop"},
    healthySeconds = {default = 60, description = "A run this long counts as working: the next error starts a fresh count"},
  },
}
