local consts = require("scripts.consts")

data:extend({
  {
    type = "shortcut",
    name = consts.OPEN_GUI_SHORTCUT_NAME,
    order = "zzz-" .. consts.OPEN_GUI_SHORTCUT_NAME,
    action = "lua",
    icon = consts.resource("open-gui-x32.png"),
    icon_size = 32,
    small_icon = consts.resource("open-gui-x24.png"),
    small_icon_size = 24,
  },
})
