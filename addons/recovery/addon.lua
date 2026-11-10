return {
  name = "recovery",
  version = "1.3.0",
  description = "Restarts a failing program after a pause, cleans up its listeners, safe state after minutes of errors",
  requires = {},
  components = {},
  settings = {
    retrySeconds = {default = 30, description = "Seconds to wait before starting again after an error"},
    giveUpMinutes = {default = 5, description = "Minutes of failing in a row before the safe state and stop"},
    healthySeconds = {default = 60, description = "A run this long counts as working: the next error starts a fresh count"},
    keepTrying = {default = false, description = "After giving up, keep the safe state but go on trying every keepTryingSeconds instead of stopping"},
    keepTryingSeconds = {default = 60, description = "Seconds between tries after giving up, with keepTrying"},
  },
}
