local consts = require("scripts.consts")

local ShortcutDict = {}

--- @class ShortcutDictEntry
--- @field name ShortcutName
--- @field localised_name LocalisedString
--- @field icon SpritePath
--- @field style ShortcutStyle
--- @field item_name string
--- @field toggleable boolean
--- @field is_modded boolean

--- @alias ShortcutDict table<ShortcutName, ShortcutDictEntry>

--- @type table<ShortcutName, boolean>
local BASE_SHORTCUTS = {
  ["toggle-alt-mode"] = true,
  ["undo"] = true,
  ["redo"] = true,
  ["copy"] = true,
  ["cut"] = true,
  ["paste"] = true,
  ["import-string"] = true,
  ["give-blueprint"] = true,
  ["give-blueprint-book"] = true,
  ["give-deconstruction-planner"] = true,
  ["give-upgrade-planner"] = true,
  ["toggle-personal-roboport"] = true,
  ["toggle-equipment-movement-bonus"] = true,
  ["give-copper-wire"] = true,
  ["give-red-wire"] = true,
  ["give-green-wire"] = true,
  ["give-spidertron-remote"] = true,
  ["give-discharge-defense-remote"] = true,
  ["give-artillery-targeting-remote"] = true,
}

--- @type ShortcutDict|nil
local dict = nil

--- Get a dictionary of all shortcuts from prototypes, including hidden ones.
---
--- This function is cached, so calling it multiple times is cheap.
---
--- Stage: runtime
---
--- @return ShortcutDict
function ShortcutDict.get_all()
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
          toggleable = shortcut.toggleable or false,
          is_modded = not BASE_SHORTCUTS[shortcut.name],
        }
      end
    end
  end
  return dict
end

--- Get a shortcut entry by name.
---
--- Stage: runtime
---
--- @param name ShortcutName
--- @return ShortcutDictEntry|nil
function ShortcutDict.get(name)
  return ShortcutDict.get_all()[name]
end

return ShortcutDict
