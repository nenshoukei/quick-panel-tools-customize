local consts = require("scripts.shared.consts")
local TableUtils = require("scripts.shared.table-utils")
local Customization = require("scripts.shared.customization")

--- mod-data for storing all shortcuts including hidden ones
--- and also for storing fields not provided by LuaGuiPrototype
--- @type ShortcutListModData
local mod_data = {
  shortcut_list = {},
}
data:extend({
  {
    type = "mod-data",
    name = consts.SHORTCUT_LIST_DATA_NAME,
    data = mod_data,
  },
})
local shortcut_list = mod_data.shortcut_list

--- To remove shortcuts, we have to do `data.raw["shortcuts"][name] = nil`.
--- (`hidden` property is ignored on Quick Panel)
---
--- If other mods try to modify removed shortcuts, it will cause an error.
--- So we store removed shortcuts and return them when accessed with `__index`.
--- In addition, we can modify defined shortcuts by other mods using `__newindex`.
---
--- @type table<ShortcutName, data.ShortcutPrototype>
local removed_shortcuts = {}

--- Store a shortcut data as ItemPrototype for Customize GUIs
--- @param shortcut data.ShortcutPrototype
local function store_shortcut(shortcut)
  shortcut_list[#shortcut_list + 1] = {
    name = shortcut.name,
    style = shortcut.style,
    toggleable = shortcut.toggleable,
  }

  data:extend({
    {
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
    },
  })
end

local function fill_gaps_with_placeholders(from_index, until_index)
  for i = from_index, until_index do
    -- Placeholder shortcut that does nothing, always disabled
    data:extend({
      {
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
      },
    })
  end
end

local function remove_placeholder(index)
  rawset(data.raw["shortcut"], consts.PLACEHOLDER_SHORTCUT_NAME_PREFIX .. index, nil)
end

--- @type table<string, number> Value is index. `-1` means removed.
local customized_indexes = {}
local last_customized_index = 0

--- Just for scoping local variables
do
  --- Load the customization from startup settings
  local customization = Customization.from_settings()

  local shortcut_prototypes = data.raw["shortcut"]
  local new_shortcuts = TableUtils.shallow_copy(shortcut_prototypes)

  for i, name in ipairs(customization.shortcuts) do
    -- Skipping placeholders. We don't make them until they are needed, so that trailing placeholders are not created.
    if name ~= "" then
      customized_indexes[name] = i

      local shortcut = shortcut_prototypes[name]
      if shortcut then
        -- Shortcut is defined. Set order and create placeholders if needed
        fill_gaps_with_placeholders(last_customized_index + 1, i - 1)
        last_customized_index = i

        shortcut.order = ("%010d"):format(i)
        shortcut.subgroup = nil -- subgroup makes sorting not work as expected
        store_shortcut(shortcut)
        new_shortcuts[name] = nil
      end
    end
  end

  for _, name in ipairs(customization.hidden_shortcuts) do
    customized_indexes[name] = -1
    local shortcut = shortcut_prototypes[name]
    if shortcut then
      store_shortcut(shortcut)
      removed_shortcuts[name] = shortcut

      -- Remove the shortcut!
      shortcut_prototypes[shortcut.name] = nil
      new_shortcuts[shortcut.name] = nil
    end
  end

  for _, shortcut in pairs(new_shortcuts) do
    -- New shortcuts should always be after customized shortcuts
    shortcut.order = "NEW__" .. (shortcut.order or "")
    shortcut.subgroup = nil
    store_shortcut(shortcut)
  end
end

--- Hook data.raw["shortcut"]
do
  local metatable = getmetatable(data.raw["shortcut"])
  if not metatable then
    metatable = {}
    setmetatable(data.raw["shortcut"], metatable)
  end

  local original__index = metatable.__index
  local original__newindex = metatable.__newindex

  --- @param self table
  --- @param key string
  --- @return data.ShortcutPrototype|nil
  metatable.__index = function (self, key)
    if removed_shortcuts[key] then
      -- Return a virtual shortcut prototype for removed key to avoid crash
      return removed_shortcuts[key]
    end
    return original__index and original__index(self, key) or nil
  end

  --- @param self table
  --- @param key string
  --- @param value data.ShortcutPrototype|nil
  metatable.__newindex = function (self, key, value)
    if value then
      -- New shortcut prototype is defined
      local index = customized_indexes[key]
      if index == -1 then
        -- Shortcut is removed
        removed_shortcuts[key] = value
        return
      elseif index then
        -- Shortcut is customized
        if index > last_customized_index then
          fill_gaps_with_placeholders(last_customized_index + 1, index - 1)
          last_customized_index = index
        else
          remove_placeholder(index)
        end
        value.order = ("%010d"):format(index)
        value.subgroup = nil
      else
        -- Shortcut is not customized
        value.order = "NEW__" .. (value.order or "")
        value.subgroup = nil
      end
      store_shortcut(value)
    end

    if original__newindex then
      original__newindex(self, key, value)
    else
      rawset(self, key, value)
    end
  end
end
