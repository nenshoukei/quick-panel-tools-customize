--- @module "__core__.lualib.event_handler"
local consts = require("scripts.consts")
local Customization = require("scripts.lib.customization")
local CustomizeGui = require("scripts.gui.customize-gui")

--- @class CustomizeGuiControl : event_handler
local CustomizeGuiControl = {}

function CustomizeGuiControl.on_init()
  --- @type table<integer, CustomizeGui> key is player_index
  storage.customize_guis = {}
end

function CustomizeGuiControl.on_load()
  for _, customize_gui in pairs(storage.customize_guis) do
    customize_gui:load()
  end
end

--- @param event ConfigurationChangedData
function CustomizeGuiControl.on_configuration_changed(event)
  if event.mod_startup_settings_changed then
    -- Startup Settings changed, so we rebuild Customization from it
    local customization = Customization.from_settings()
    for _, customize_gui in pairs(storage.customize_guis) do
      customize_gui:set_customization(customization)
    end

    -- Update placeholders for all players
    for _, player in pairs(game.players) do
      CustomizeGuiControl.update_placeholders(player)
    end
  end
end

--- @param player LuaPlayer
function CustomizeGuiControl.update_placeholders(player)
  -- Make placeholder shortcuts unavailable
  local placeholder_subgroup = prototypes.item_subgroup[consts.PLACEHOLDER_SUBGROUP_NAME]
  for name, shortcut in pairs(prototypes.shortcut) do
    if shortcut.subgroup == placeholder_subgroup then
      player.set_shortcut_available(name, false)
    end
  end
end

--- @param player_index integer
function CustomizeGuiControl.toggle_customize_gui(player_index)
  local customize_gui = storage.customize_guis[player_index]
  if not customize_gui then
    local player = game.get_player(player_index)
    if not player then return end

    customize_gui = CustomizeGui.new(player)
    storage.customize_guis[player_index] = customize_gui
  end

  customize_gui:toggle()
end

CustomizeGuiControl.events = {
  --- @param event EventData.on_player_created
  [defines.events.on_player_created] = function (event)
    local player = game.get_player(event.player_index)
    if player then
      CustomizeGuiControl.update_placeholders(player)
    end
  end,

  --- @param event EventData.on_player_removed
  [defines.events.on_player_removed] = function (event)
    storage.customize_guis[event.player_index] = nil
  end,

  --- @param event EventData.on_lua_shortcut
  [defines.events.on_lua_shortcut] = function (event)
    if event.prototype_name == consts.OPEN_GUI_SHORTCUT_NAME then
      CustomizeGuiControl.toggle_customize_gui(event.player_index)
    end
  end,

  --- @param event EventData.CustomInputEvent
  [consts.OPEN_GUI_CUSTOM_INPUT_NAME] = function (event)
    CustomizeGuiControl.toggle_customize_gui(event.player_index)
  end,
}

return CustomizeGuiControl
