local consts = require("scripts.consts")

data:extend({
  -- This is a dummy technology for making placeholder shortcuts disabled
  {
    type = "technology",
    name = consts.DUMMY_TECHNOLOGY_NAME,
    icon = consts.resource("blank-x32.png"),
    icon_size = 32,
    enabled = false,
    hidden = true,
    research_trigger = {
      type = "scripted",
      icon = consts.resource("blank-x32.png"),
      icon_size = 32,
    },
  },
})
