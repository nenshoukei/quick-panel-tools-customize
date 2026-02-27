local consts = require("scripts.consts")

data:extend({
  {
    type = "custom-input",
    name = consts.OPEN_GUI_CUSTOM_INPUT_NAME,
    key_sequence = "",
    controller_key_sequence = "controller-lefttrigger + controller-start",
    consuming = "game-only",
  },
})
