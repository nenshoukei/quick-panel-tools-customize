-- Helper functions for busted tests
-- This file is automatically loaded by busted

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
    ["quick-panel-tools-customize-customize-json"] = {
      value = "",
    },
  },
}

-- Mock helpers functions
_G.helpers = {
  table_to_json = function (tbl)
    return '{"s":' .. serpent.line(tbl.s) .. ',"h":' .. serpent.line(tbl.h) .. "}"
  end,
  json_to_table = function (json_string)
    print("DEBUG: json_to_table called with:", json_string)
    if not json_string then
      print("DEBUG: returning nil for nil input")
      return nil
    end

    -- Remove leading/trailing whitespace
    json_string = json_string:match("^%s*(.-)%s*$") or json_string

    -- Simple mock for valid JSON
    if json_string == '{"s":["a","b"],"h":["c"]}' then
      print("DEBUG: returning valid table")
      return { s = { "a", "b" }, h = { "c" } }
    elseif json_string == '    {"s":["a","b"],"h":["c"]}' then
      print("DEBUG: returning valid table (with spaces)")
      return { s = { "a", "b" }, h = { "c" } }
    elseif json_string == '{"s":[],"h":[]}' then
      print("DEBUG: returning empty table")
      return { s = {}, h = {} }
    elseif json_string == "invalid" then
      print("DEBUG: returning nil for invalid")
      return nil
    elseif json_string == '{"s":"not_array","h":[]}' then
      return { s = "not_array", h = {} }
    elseif json_string == '{"s":[],"h":"not_array"}' then
      return { s = {}, h = "not_array" }
    elseif json_string == "not_json" then
      return nil
    else
      -- For any other string, return nil (invalid JSON)
      print("DEBUG: returning nil for unknown:", json_string)
      return nil
    end
  end,
}

-- Mock serpent for table_to_json
_G.serpent = {
  line = function (obj)
    if type(obj) == "table" then
      local result = {}
      for i, v in ipairs(obj) do
        result[i] = '"' .. v .. '"'
      end
      return "[" .. table.concat(result, ",") .. "]"
    else
      return '"' .. tostring(obj) .. '"'
    end
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
