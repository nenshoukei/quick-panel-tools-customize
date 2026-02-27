local consts = require("scripts.consts")
local Customization = require("scripts.lib.customization")

--- Load the customization from startup settings
local customization = Customization.from_settings()

--- Prototypes for data:extend() later
--- @type data.AnyPrototype[]
local prototypes = {}

--- mod-data for storing all shortcuts including hidden ones
--- and also for storing fields not provided by LuaGuiPrototype
--- @type ShortcutListModDataItem[]
local shortcut_list = {}

--- @type number[]
local placeholder_indexes = {}

--- @type table<ShortcutName, boolean>
local stored_shortcuts = {}

--- Store a shortcut data as ItemPrototype for Customize GUI
--- @param shortcut data.ShortcutPrototype
local function store_shortcut(shortcut)
  shortcut_list[#shortcut_list + 1] = {
    name = shortcut.name,
    style = shortcut.style,
    toggleable = shortcut.toggleable,
  }
  stored_shortcuts[shortcut.name] = true

  prototypes[#prototypes + 1] = {
    type = "item",
    name = consts.SHORTCUT_ITEM_NAME_PREFIX .. shortcut.name,
    localised_name = shortcut.localised_name or { "shortcut-name." .. shortcut.name },
    localised_description = shortcut.localised_description or { "shortcut-description." .. shortcut.name },
    icons = shortcut.icons,
    icon = shortcut.icon,
    icon_size = shortcut.icon_size,
    order = shortcut.order,
    subgroup = consts.SHORTCUT_ITEM_SUBGROUP_NAME,
    stack_size = 1,
    flags = { "not-stackable", "hide-from-bonus-gui", "only-in-cursor" },
    auto_recycle = false,
    hidden = true,
  }
end

for i, name in ipairs(customization.shortcuts) do
  if name == "" then
    -- Insert a placeholder shortcut
    placeholder_indexes[#placeholder_indexes + 1] = i
    prototypes[#prototypes + 1] = {
      type = "shortcut",
      name = consts.PLACEHOLDER_SHORTCUT_NAME_PREFIX .. i,
      localised_name = "",
      localised_description = "",
      order = ("%010d"):format(i),
      action = "lua",
      icon = consts.resource("blank-x32.png"),
      icon_size = 32,
      small_icon = consts.resource("blank-x24.png"),
      small_icon_size = 24,
    }
  else
    local shortcut = data.raw["shortcut"][name]
    if shortcut then
      shortcut.order = ("%010d"):format(i)
      store_shortcut(shortcut)
    end
  end
end

for i, name in ipairs(customization.hidden_shortcuts) do
  local shortcut = data.raw["shortcut"][name]
  if shortcut then
    store_shortcut(shortcut)

    -- Remove the shortcut! (It's dangerous, but no other way to do it...)
    --
    -- To avoid compatibility issue:
    --   * We use `zzz-` prefix for mod name, so that data-final-fixes.lua will be executed at the very last.
    --   * Toggleable shortcuts by mod cannot be hidden on Customize GUI, so that `player.set_shortcut_toggled()` works.
    --
    -- However, `player.set_shortcut_available()` still breaks the compatibility.
    -- There is no way to know whether it will be called on shortcuts created by other mods.
    data.raw["shortcut"][shortcut.name] = nil
  end
end

for name, shortcut in pairs(data.raw["shortcut"]) do
  if not stored_shortcuts[name] then
    -- New shortcuts should always be after customized shortcuts
    shortcut.order = "NEW__" .. shortcut.order
    store_shortcut(shortcut)
  end
end

--- @type ShortcutListModData
local mod_data = {
  shortcut_list = shortcut_list,
  placeholder_indexes = placeholder_indexes,
}
prototypes[#prototypes + 1] = {
  type = "mod-data",
  name = consts.SHORTCUT_LIST_DATA_NAME,
  data = mod_data,
}

data:extend(prototypes)
