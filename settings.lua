local consts = require("scripts.consts")

data:extend({
  {
    type          = "string-setting",
    name          = consts.CUSTOMIZE_JSON_SETTING_NAME,
    setting_type  = "startup",
    default_value = "",
    allow_blank   = true,
    auto_trim     = true,
  },
})
