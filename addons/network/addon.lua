return {
  name = "network",
  version = "1.0.0",
  description = "Messages between OC computers over a network card: send, broadcast, ask and get an answer",
  requires = {},
  components = {"modem"},
  settings = {
    port = {default = 4711, description = "Port all programs using this addon talk on"},
    timeoutSeconds = {default = 5, description = "How long request() waits for an answer"},
  },
}
