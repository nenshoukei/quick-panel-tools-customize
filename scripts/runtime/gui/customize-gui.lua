local consts = require("scripts.shared.consts")
local Customization = require("scripts.shared.customization")
local GuiComponent = require("scripts.runtime.lib.gui-component")
local GuiParts = require("scripts.runtime.gui.gui-parts")
local ShortcutEditor = require("scripts.runtime.gui.shortcut-editor")

--- @class CustomizeGui : GuiComponent
--- @field player LuaPlayer
--- @field customization Customization
--- @field editor ShortcutEditor
--- @field window LuaGuiElement|nil
local CustomizeGui = GuiComponent.define("CustomizeGui")

local TAB_CUSTOMIZE = 1
local TAB_JSON = 2

--- @param player LuaPlayer
--- @return CustomizeGui
function CustomizeGui.new(player)
  local customization = Customization.from_settings()
  return setmetatable({
    player = player,
    customization = customization,
    editor = ShortcutEditor.new(player, customization),
  }, CustomizeGui)
end

function CustomizeGui:load()
  GuiComponent.load(self)
  self.editor:load()
end

function CustomizeGui:destroy()
  if self.window then
    self.editor:destroy()

    if self.player.opened == self.window then
      self.player.opened = nil
    end
    if self.window and self.window.valid then
      self.window.destroy()
    end
    self.window = nil
  end
  GuiComponent.destroy(self)
end

function CustomizeGui:set_customization(customization)
  self.customization = customization
  self.editor:reload(customization)
  self:update()
end

function CustomizeGui:open()
  if self.window and self.window.valid then
    self:update()
    self:focus()
  else
    self:render()
    self:focus()
  end
end

function CustomizeGui:close()
  self:destroy()
end

function CustomizeGui:toggle()
  if self.window then
    self:close()
  else
    self:open()
  end
end

function CustomizeGui:focus()
  if self.window and self.window.valid then
    self.window.bring_to_front()
    self.window.force_auto_center()
    self.player.opened = self.window
    self.window.focus()
  end
end

function CustomizeGui:render()
  local window_name = consts.name(self.component_name)

  -- Destroy old window
  local window = self.player.gui.screen[window_name]
  if window and window.valid then
    if self.player.opened == window then
      self.player.opened = nil
    end
    window.destroy()
  end

  window = GuiParts.window(self.player, window_name, {
    style = consts.name("customize-gui-window"),
  })
  self:listen_to_gui_events(window, {
    [defines.events.on_gui_closed] = self.close,
  })

  local titlebar = GuiParts.titlebar(window, consts.str("customize-gui-title"))
  local close_button = GuiParts.close_button(titlebar)
  self:listen_to_gui_events(close_button, {
    [defines.events.on_gui_click] = self.close,
  })

  local content_frame = window.add({
    type = "frame",
    name = "content_frame",
    style = consts.name("customize-gui-content"),
  })

  local tabbed_pane = content_frame.add({
    type = "tabbed-pane",
    name = "tabbed_pane",
    style = consts.name("customize-gui-tabbed-pane"),
  })
  self:listen_to_gui_events(tabbed_pane, {
    [defines.events.on_gui_selected_tab_changed] = self.handle_tab_changed,
  })

  local customize_tab = tabbed_pane.add({
    type = "tab",
    caption = consts.str("customize"),
  })
  local customize_content = tabbed_pane.add({
    type = "flow",
    name = "customize_content",
    direction = "vertical",
    style = consts.name("customize-gui-tab-content"),
  })
  tabbed_pane.add_tab(customize_tab, customize_content)

  self.editor:render(customize_content)

  local json_tab = tabbed_pane.add({
    type = "tab",
    caption = consts.str("json"),
  })
  local json_content = tabbed_pane.add({
    type = "flow",
    name = "json_content",
    direction = "vertical",
    style = consts.name("customize-gui-tab-content"),
  })
  tabbed_pane.add_tab(json_tab, json_content)

  GuiParts.paragraphs(json_content, {
    consts.str("json-description-1"),
    consts.str("json-description-2"),
    consts.str("json-description-3"),
  })

  local json_text_box = json_content.add({
    type = "text-box",
    name = "json_text_box",
    text = "",
    style = consts.name("json-text-box"),
    game_controller_interaction = defines.game_controller_interaction.always,
  })
  json_text_box.read_only = true
  json_text_box.word_wrap = true
  self:listen_to_gui_events(json_text_box, {
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
  self:listen_to_gui_events(customize_button, {
    [defines.events.on_gui_click] = self.handle_customize_button_clicked,
  })
  GuiParts.footer_drag_handle(footer)
  local view_json_button = footer.add({
    type = "button",
    name = "view_json_button",
    style = "forward_button",
    caption = consts.str("json"),
  })
  self:listen_to_gui_events(view_json_button, {
    [defines.events.on_gui_click] = self.handle_view_json_button_clicked,
  })

  self.window = window
end

function CustomizeGui:update()
  if self.window and self.window.valid then
    self.editor:update()
    self:update_json_text_box()
    self:update_footer()
  else
    self.window = nil
  end
end

function CustomizeGui:get_tabbed_pane()
  return self.window.content_frame.tabbed_pane
end

function CustomizeGui:get_json_text_box()
  return self:get_tabbed_pane().json_content.json_text_box
end

function CustomizeGui:update_json_text_box()
  local customization = self.editor:get_customization()
  self:get_json_text_box().text = Customization.to_json(customization)
end

function CustomizeGui:update_footer()
  if not self.window then return end
  local selected_tab = self:get_tabbed_pane().selected_tab_index or TAB_CUSTOMIZE
  local footer = self.window.footer
  footer.customize_button.visible = selected_tab == TAB_JSON
  footer.view_json_button.visible = selected_tab == TAB_CUSTOMIZE
end

--- @param event EventData.on_gui_selected_tab_changed
function CustomizeGui:handle_tab_changed(event)
  if event.element.selected_tab_index == TAB_JSON then
    self:update_json_text_box()
  end
  self:update_footer()
end

--- @param event EventData.on_gui_click
function CustomizeGui:handle_customize_button_clicked(event)
  self:get_tabbed_pane().selected_tab_index = TAB_CUSTOMIZE
  self:update_footer()
end

--- @param event EventData.on_gui_click
function CustomizeGui:handle_view_json_button_clicked(event)
  self:get_tabbed_pane().selected_tab_index = TAB_JSON
  self:update_json_text_box()
  self:update_footer()

  local text_box = self:get_json_text_box()
  text_box.focus()
  text_box.select_all()
end

--- @param event EventData.on_gui_click
function CustomizeGui:handle_json_text_box_clicked(event)
  event.element.select_all()
end

return CustomizeGui
