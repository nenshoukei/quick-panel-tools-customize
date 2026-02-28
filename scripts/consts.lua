local PREFIX = "mks-qptc"
local MOD_DIR = "__quick-panel-tools-customize__"
local RESOURCES_DIR = MOD_DIR .. "/resources"

--- Returns a per-mod unique name for the given key.
---
--- @param key string
--- @return string
local function name(key)
  return PREFIX .. "-" .. key
end

--- Returns a localized string for the given key.
---
--- @param key string
--- @vararg string|number
--- @return data.LocalisedString
local function str(key, ...)
  return { PREFIX .. "." .. key, ... }
end

--- Returns a resource file path for the given file name.
---
--- @param file_name string
--- @return string
local function resource(file_name)
  return RESOURCES_DIR .. "/" .. file_name
end

local consts = {
  PREFIX = PREFIX,
  MOD_DIR = MOD_DIR,
  RESOURCES_DIR = RESOURCES_DIR,
  name = name,
  str = str,
  resource = resource,

  SHORTCUT_ITEM_SUBGROUP_NAME = name("shortcut"),
  SHORTCUT_ITEM_NAME_PREFIX = name("shortcut-"),
  SHORTCUT_LIST_DATA_NAME = name("shortcut-list"),
  PLACEHOLDER_SHORTCUT_NAME_PREFIX = name("placeholder-"),
  OPEN_GUI_SHORTCUT_NAME = name("open-customize-gui"),
  OPEN_GUI_CUSTOM_INPUT_NAME = name("open-customize-gui"),
  CUSTOMIZE_JSON_SETTING_NAME = name("customize-json"),
}

return consts
