-- Helper functions for busted tests
-- This file is automatically loaded by busted

local cjson = require("cjson.safe")

_G.serpent = require("serpent")

-- Mock Factorio globals for testing
--- @diagnostic disable-next-line: missing-fields
_G.data = {
  raw = {
    shortcut = {},
    item = {},
    ["mod-data"] = {},
  },
  extend = function () end,
}

--- @diagnostic disable-next-line: missing-fields
_G.prototypes = {
  shortcut = {},
  item = {},
  ["mod-data"] = {},
}

--- @diagnostic disable-next-line: missing-fields
_G.game = {
  players = {},
}

--- @diagnostic disable-next-line: missing-fields
_G.script = {
  register_metatable = function () end,
}

_G.storage = {}

_G.log = function () end

-- Mock settings
_G.settings = {
  startup = {
    ["mks-qptc-customize-json"] = {
      value = "",
    },
  },
}

-- Mock helpers functions
_G.helpers = {
  table_to_json = function (tbl)
    return cjson.encode(tbl)
  end,
  json_to_table = function (json_string)
    return cjson.decode(json_string)
  end,
}

-- Common test utilities
local function create_mock_shortcut(name, order)
  return {
    name = name,
    order = order or "zzzz",
    localised_name = { "shortcut-name." .. name },
    localised_description = { "shortcut-description." .. name },
    icon = "__base__/graphics/icons/shortcut/toolbar.png",
    icon_size = 32,
  }
end

local function create_mock_item(name, order)
  return {
    name = name,
    localised_name = { "item-name." .. name },
    order = order or "zzzz",
    icon = "__base__/graphics/icons/shortcut/toolbar.png",
    icon_size = 32,
  }
end

return {
  create_mock_shortcut = create_mock_shortcut,
  create_mock_item = create_mock_item,
}
