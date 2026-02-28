local consts = require("scripts.consts")

data:extend({
  {
    type = "item-subgroup",
    name = consts.SHORTCUT_ITEM_SUBGROUP_NAME,
    group = "other",
    hidden = true,
  },
  {
    type = "item-subgroup",
    name = consts.PLACEHOLDER_SUBGROUP_NAME,
    group = "other",
    hidden = true,
  },
})
