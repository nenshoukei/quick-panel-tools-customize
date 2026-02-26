local consts = require("scripts.consts")

local ShortcutDict = {}

--- @class ShortcutDictEntry
--- @field name ShortcutName
--- @field localised_name LocalisedString
--- @field icon SpritePath
--- @field style ShortcutStyle
--- @field item_name string

--- @alias ShortcutDict table<ShortcutName, ShortcutDictEntry>

--- @type ShortcutDict|nil
local dict = nil

--- Get a dictionary of all shortcuts from prototypes, including hidden ones.
---
--- This function is cached, so calling it multiple times is cheap.
---
--- Stage: runtime
---
--- @return ShortcutDict
function ShortcutDict.get_from_prototypes()
  if not dict then
    dict = {}

    local mod_data = prototypes.mod_data[consts.SHORTCUT_LIST_DATA_NAME]
    local shortcut_list_data = assert(mod_data and mod_data.data, "mod-data not found") --[[@as ShortcutListModData]]

    for _, shortcut in ipairs(shortcut_list_data.shortcut_list) do
      local item_name = consts.SHORTCUT_ITEM_NAME_PREFIX .. shortcut.name
      local item_proto = prototypes.item[item_name]
      if item_proto then
        dict[shortcut.name] = {
          name = shortcut.name,
          localised_name = item_proto.localised_name,
          icon = "item/" .. item_name,
          style = shortcut.style or "default",
          item_name = item_name,
        }
      end
    end
  end
  return dict
end

return ShortcutDict
