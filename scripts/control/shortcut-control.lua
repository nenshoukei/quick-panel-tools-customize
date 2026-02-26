--- @module "__core__.lualib.event_handler"
local consts = require("scripts.consts")
local Customization = require("scripts.lib.customization")
local CustomizeGui = require("scripts.gui.customize-gui")

--- @class ShortcutControl : event_handler
local ShortcutControl = {}

function ShortcutControl.on_init()
  --- @type table<integer, CustomizeGui> key is player_index
  storage.customize_guis = {}
end

function ShortcutControl.on_load()
  for _, customize_gui in pairs(storage.customize_guis) do
    customize_gui:load()
  end
end

--- @param event ConfigurationChangedData
function ShortcutControl.on_configuration_changed(event)
  if event.mod_startup_settings_changed then
    -- Startup Settings changed, so we rebuild Customization from it
    local customization = Customization.from_settings()
    for _, customize_gui in pairs(storage.customize_guis) do
      customize_gui:set_customization(customization)
    end

    -- Update placeholders for all players
    for _, player in pairs(game.players) do
      ShortcutControl.update_placeholders(player)
    end
  end
end

--- @param player LuaPlayer
function ShortcutControl.update_placeholders(player)
  -- Make placeholder shortcuts unavailable
  local mod_data = prototypes.mod_data[consts.SHORTCUT_LIST_DATA_NAME]
  local shortcut_list_data = assert(mod_data and mod_data.data, "mod-data not found") --[[@as ShortcutListModData]]
  for _, index in ipairs(shortcut_list_data.placeholder_indexes) do
    player.set_shortcut_available(consts.PLACEHOLDER_SHORTCUT_NAME_PREFIX .. index, false)
  end
end

ShortcutControl.events = {
  --- @param event EventData.on_player_created
  [defines.events.on_player_created] = function (event)
    local player = game.get_player(event.player_index)
    if player then
      ShortcutControl.update_placeholders(player)
    end
  end,

  --- @param event EventData.on_lua_shortcut
  [defines.events.on_lua_shortcut] = function (event)
    if event.prototype_name == consts.OPEN_GUI_SHORTCUT_NAME then
      local customize_gui = storage.customize_guis[event.player_index]
      if not customize_gui then
        local player = game.get_player(event.player_index)
        if not player then return end

        customize_gui = CustomizeGui.new(player)
        storage.customize_guis[event.player_index] = customize_gui
      end

      customize_gui:open()
    end
  end,
}

return ShortcutControl
