return {
  name = "remote-control",
  version = "1.0.0",
  description = "Commands a program offers to other computers (status, stop, switch...), only for allowed computers",
  requires = {"network@1"},
  components = {"modem"},
  settings = {
    allowFrom = {default = {}, description = 'Card addresses (or their starts) of computers allowed to send commands; {"*"} allows every computer'},
  },
}
