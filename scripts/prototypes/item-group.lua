local consts = require("scripts.consts")

data:extend({
  {
    type = "item-subgroup",
    name = consts.SHORTCUT_ITEM_SUBGROUP_NAME,
    group = "other",
    order = "zzz-" .. consts.SHORTCUT_ITEM_SUBGROUP_NAME,
    hidden = true,
  },
})
