local consts = require("scripts.consts")

data:extend({
  {
    type = "custom-input",
    name = consts.name("customize-gui"),
    key_sequence = "",
    controller_key_sequence = "controller-lefttrigger + controller-start",
    consuming = "game-only",
  },
})
