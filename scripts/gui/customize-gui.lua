local consts = require("scripts.consts")
local Customization = require("scripts.lib.customization")
local GuiComponent = require("scripts.lib.gui-component")
local GuiParts = require("scripts.gui.gui-parts")
local ShortcutEditor = require("scripts.gui.shortcut-editor")

local CustomizeGui = {}

--- @class CustomizeGui : GuiComponent
--- @field player LuaPlayer
--- @field customization Customization
--- @field editor ShortcutEditor
--- @field window LuaGuiElement|nil
--- @field editor_container LuaGuiElement|nil
--- @field json_text_box LuaGuiElement|nil
--- @field json_text string|nil
local CustomizeGuiMethods = {}

local metatable = GuiComponent.define("CustomizeGui", CustomizeGuiMethods)

local TAB_CUSTOMIZE = 1
local TAB_JSON = 2

--- @param self CustomizeGui
--- @return CustomizeGui
function CustomizeGui.setmetatable(self)
  return setmetatable(self, metatable)
end

--- @param player LuaPlayer
--- @return CustomizeGui
function CustomizeGui.new(player)
  local customization = Customization.from_settings()
  return CustomizeGui.setmetatable({
    player = player,
    customization = customization,
    editor = ShortcutEditor.new(player, customization),
  })
end

function CustomizeGui.on_init()
  --- @type table<integer, CustomizeGui> key is player_index
  storage.customize_guis = {}
end

function CustomizeGui.on_load()
  for player_index, customize_gui in pairs(storage.customize_guis) do
    local player = game.get_player(player_index)
    if player then
      CustomizeGui.setmetatable(customize_gui)
      customize_gui.player = player
      customize_gui:on_load()
    else
      storage.customize_guis[player_index] = nil
    end
  end
end

--- @param event ConfigurationChangedData
function CustomizeGui.on_configuration_changed(event)
  if event.mod_startup_settings_changed then
    -- Startup Settings changed, so we rebuild Customization from it
    local customization = Customization.from_settings()
    for _, customize_gui in pairs(storage.customize_guis) do
      customize_gui:set_customization(customization)
    end
  end
end

CustomizeGui.events = {
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

function CustomizeGuiMethods:on_load()
  ShortcutEditor.setmetatable(self.editor)
  self.editor:on_load()

  if self.window and self.window.valid then
    self:render()
  else
    self.window = nil
  end
end

function CustomizeGuiMethods:set_customization(customization)
  self.customization = customization
  self.editor:reload(customization)

  if self.editor_container then
    self.editor:render(self.editor_container)
  end
end

function CustomizeGuiMethods:open()
  if self.window and self.window.valid then
    self:focus()
  else
    self:render()
    self:focus()
  end
end

function CustomizeGuiMethods:render()
  local window_name = consts.name("customize-gui-window-" .. self.player.index)

  -- Destroy old window
  local window = self.player.gui.screen[window_name]
  if window and window.valid then
    if self.player.opened == window then
      self.player.opened = nil
    end
    window.destroy()
    self:clear_all_event_listeners()
  end

  window = GuiParts.window(self.player, window_name)
  self:listen_events(window, {
    [defines.events.on_gui_closed] = self.handle_gui_closed,
  })

  local titlebar = GuiParts.titlebar(window, consts.str("customize-gui-title"))
  local close_button = GuiParts.close_button(titlebar)
  self:listen_events(close_button, {
    [defines.events.on_gui_click] = self.handle_close_button_clicked,
  })

  local content_frame = window.add({
    type = "frame",
    name = "content_frame",
    style = "inside_deep_frame",
  })

  local tabbed_pane = content_frame.add({
    type = "tabbed-pane",
    name = "tabbed_pane",
  })
  self:listen_events(tabbed_pane, {
    [defines.events.on_gui_selected_tab_changed] = self.handle_tab_changed,
  })

  local customize_tab = tabbed_pane.add({
    type = "tab",
    caption = consts.str("customize"),
  })
  local customize_content = tabbed_pane.add({
    type = "flow",
    direction = "vertical",
    style = consts.name("tab-content"),
  })
  tabbed_pane.add_tab(customize_tab, customize_content)

  self.editor:render(customize_content)

  local json_tab = tabbed_pane.add({
    type = "tab",
    caption = consts.str("json"),
  })
  local json_content = tabbed_pane.add({
    type = "flow",
    direction = "vertical",
    style = consts.name("tab-content"),
  })
  tabbed_pane.add_tab(json_tab, json_content)

  GuiParts.paragraphs(json_content, {
    consts.str("json-description-1"),
    consts.str("json-description-2"),
  })

  local json_text_box = json_content.add({
    type = "text-box",
    text = "",
    style = consts.name("json-text-box"),
    game_controller_interaction = defines.game_controller_interaction.always,
  })
  json_text_box.read_only = true
  self:listen_events(json_text_box, {
    [defines.events.on_gui_click] = self.handle_json_text_box_clicked,
  })

  local footer = GuiParts.footer(window, { name = "footer" })
  local customize_button = footer.add({
    type = "button",
    name = "customize_button",
    style = "back_button",
    caption = consts.str("customize"),
    visible = false,
  })
  self:listen_events(customize_button, {
    [defines.events.on_gui_click] = self.handle_customize_button_clicked,
  })
  GuiParts.footer_drag_handle(footer)
  local view_json_button = footer.add({
    type = "button",
    name = "view_json_button",
    style = "forward_button",
    caption = consts.str("json"),
  })
  self:listen_events(view_json_button, {
    [defines.events.on_gui_click] = self.handle_view_json_button_clicked,
  })

  self.window = window
  self.editor_container = customize_content
  self.json_text_box = json_text_box
  self.json_text = ""
end

function CustomizeGuiMethods:close()
  if self.window then
    self:clear_all_event_listeners()

    if self.player.opened == self.window then
      self.player.opened = nil
    end

    self.editor:destroy()

    self.editor_container = nil
    self.json_text_box = nil
    self.json_text = nil

    if self.window.valid then
      self.window.destroy()
    end
    self.window = nil
  end
end

function CustomizeGuiMethods:on_destroy()
  self:close()
end

function CustomizeGuiMethods:focus()
  if self.window and self.window.valid then
    self.window.bring_to_front()
    self.window.force_auto_center()
    self.player.opened = self.window
  end
end

function CustomizeGuiMethods:update_json_text_box()
  if not self.json_text_box then return end

  local customization = self.editor:get_customization()

  self.json_text = Customization.to_json(customization)
  self.json_text_box.text = self.json_text
  self.json_text_box.focus()
  self.json_text_box.select_all()
end

function CustomizeGuiMethods:update_footer()
  if not self.window then return end
  local footer = self.window.footer
  local selected_tab_index = self.window.content_frame.tabbed_pane.selected_tab_index
  footer.customize_button.visible = selected_tab_index == TAB_JSON
  footer.view_json_button.visible = selected_tab_index == TAB_CUSTOMIZE
end

--- @param event EventData.on_gui_closed
function CustomizeGuiMethods:handle_gui_closed(event)
  self:close()
end

--- @param event EventData.on_gui_click
function CustomizeGuiMethods:handle_close_button_clicked(event)
  self:close()
end

--- @param event EventData.on_gui_selected_tab_changed
function CustomizeGuiMethods:handle_tab_changed(event)
  if event.element.selected_tab_index == TAB_JSON then
    self:update_json_text_box()
  end
  self:update_footer()
end

--- @param event EventData.on_gui_click
function CustomizeGuiMethods:handle_customize_button_clicked(event)
  self.window.content_frame.tabbed_pane.selected_tab_index = TAB_CUSTOMIZE
  self:update_footer()
end

--- @param event EventData.on_gui_click
function CustomizeGuiMethods:handle_view_json_button_clicked(event)
  self.window.content_frame.tabbed_pane.selected_tab_index = TAB_JSON
  self:update_json_text_box()
  self:update_footer()
end

--- @param event EventData.on_gui_click
function CustomizeGuiMethods:handle_json_text_box_clicked(event)
  event.element.select_all()
end

return CustomizeGui
