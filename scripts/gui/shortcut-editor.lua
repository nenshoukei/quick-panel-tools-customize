local consts = require("scripts.consts")
local utils = require("scripts.utils")
local GuiComponent = require("scripts.lib.gui-component")
local ShortcutDict = require("scripts.lib.shortcut-dict")
local ShortcutSlots = require("scripts.lib.shortcut-slots")
local GuiParts = require("scripts.gui.gui-parts")

--- @class ShortcutEditor : GuiComponent
--- @field player LuaPlayer
--- @field shortcut_slots ShortcutSlots
--- @field container LuaGuiElement|nil
local ShortcutEditor = GuiComponent.define("ShortcutEditor")

--- @class ShortcutSlotButtonTags
--- @field shortcut_name ShortcutName
--- @field slot_position ShortcutSlotPosition

--- @param player LuaPlayer
--- @param customization Customization
--- @return ShortcutEditor
function ShortcutEditor.new(player, customization)
  return setmetatable({
    player = player,
    shortcut_slots = ShortcutSlots.new_with_customization(customization),
  }, ShortcutEditor)
end

function ShortcutEditor:destroy()
  if self.container then
    if self.container.valid then
      self.container.destroy()
    end
    self.container = nil
  end
  GuiComponent.destroy(self)
end

--- @param customization Customization
function ShortcutEditor:reload(customization)
  self.shortcut_slots = ShortcutSlots.new_with_customization(customization)
end

--- @private
--- @param parent LuaGuiElement
--- @param slot ShortcutSlots.SlotInfo
--- @return LuaGuiElement
function ShortcutEditor:make_shortcut_slot_button(parent, slot)
  --- @type ShortcutSlotButtonTags
  local tags = {
    shortcut_name = slot.name or "",
    slot_position = slot.position,
  }
  local shortcut = slot.name and ShortcutDict.get(slot.name)

  local button
  if shortcut then
    button = parent.add({
      type = "sprite-button",
      style = "shortcut_bar_button" .. (shortcut.style ~= "default" and "_" .. shortcut.style or ""),
      sprite = shortcut.icon,
      tooltip = shortcut.localised_name,
      tags = tags,
    })
  else
    button = parent.add({
      type = "sprite-button",
      style = "slot_button",
      tags = tags,
    })
  end

  self:listen_to_gui_events(button, {
    [defines.events.on_gui_click] = self.handle_shortcut_button_clicked,
  })

  return button
end

--- @private
--- @param button LuaGuiElement
--- @param slot ShortcutSlots.SlotInfo
function ShortcutEditor:update_shortcut_slot_button(button, slot)
  local tags = button.tags --[[@as ShortcutSlotButtonTags]]
  if tags.shortcut_name == slot.name or (tags.shortcut_name == "" and slot.name == nil) then
    return
  end

  --- @type ShortcutSlotButtonTags
  button.tags = utils.table_merge(button.tags, {
    shortcut_name = slot.name or "",
    slot_position = slot.position,
  })

  local shortcut = slot.name and ShortcutDict.get(slot.name)
  if shortcut then
    button.sprite = shortcut.icon
    button.tooltip = shortcut.localised_name
    button.style = "shortcut_bar_button" .. (shortcut.style ~= "default" and "_" .. shortcut.style or "")
  else
    button.sprite = nil
    button.tooltip = nil
    button.style = "slot_button"
  end
end

local CENTER_INDEX = 5

--- @private
--- @param parent LuaGuiElement
--- @param page ShortcutSlots.VisiblePageInfo
--- @return LuaGuiElement
function ShortcutEditor:make_shortcut_slot_page(parent, page)
  local page_button_frame = parent.add({
    type = "frame",
    style = "slot_button_deep_frame",
    direction = "horizontal",
  })
  local page_button_table = page_button_frame.add({
    type = "table",
    name = "button_table",
    style = "slot_table",
    column_count = 3,
  })

  for slot in page.iter_slots() do
    if slot.index_in_page == CENTER_INDEX then
      page_button_table.add({
        type = "empty-widget",
        style = consts.name("shortcut-page-center"),
        game_controller_interaction = defines.game_controller_interaction.always,
      })
    end
    self:make_shortcut_slot_button(page_button_table, slot)
  end

  return page_button_frame
end

--- @private
--- @param page_button_frame LuaGuiElement
--- @param page ShortcutSlots.VisiblePageInfo
function ShortcutEditor:update_shortcut_slot_page(page_button_frame, page)
  local page_button_table = page_button_frame.button_table
  local child_index = 1
  for slot in page.iter_slots() do
    if slot.index_in_page == CENTER_INDEX then
      child_index = child_index + 1
    end
    self:update_shortcut_slot_button(page_button_table.children[child_index], slot)
    child_index = child_index + 1
  end
end

--- @param parent LuaGuiElement
function ShortcutEditor:render(parent)
  if self.container then
    self.container.clear()
  else
    self.container = parent.add({
      type = "flow",
      direction = "vertical",
    })
  end

  GuiParts.paragraphs(self.container, {
    consts.str("customize-description-1"),
    consts.str("customize-description-2"),
  })

  local shortcut_pages = self.container.add({
    type = "table",
    name = "shortcut_pages",
    style = consts.name("shortcut-pages"),
    column_count = ShortcutSlots.MINIMUM_VISIBLE_PAGE_COUNT,
  })
  for page in self.shortcut_slots:iter_visible_pages() do
    self:make_shortcut_slot_page(shortcut_pages, page)
  end

  local hidden_caption = self.container.add({
    type = "label",
    style = "caption_label",
    caption = consts.str("hidden-tools"),
  })
  hidden_caption.style.top_margin = 12
  local hidden_button_frame = self.container.add({
    type = "frame",
    name = "hidden_button_frame",
    style = "slot_button_deep_frame",
    direction = "horizontal",
  })
  local hidden_button_table = hidden_button_frame.add({
    type = "table",
    name = "button_table",
    style = "slot_table",
    column_count = ShortcutSlots.HIDDEN_SLOTS_PER_ROW,
  })
  local is_hiding_modded_shortcut = false
  for slot in self.shortcut_slots:iter_hidden_slots() do
    self:make_shortcut_slot_button(hidden_button_table, slot)
    if slot.name then
      local shortcut = ShortcutDict.get(slot.name)
      if shortcut and shortcut.is_modded then
        is_hiding_modded_shortcut = true
      end
    end
  end

  local modded_tools_warning = GuiParts.icon_label(self.container, "utility/warning_white",
    consts.str("modded-tools-warning"), { name = "modded_tools_warning" })
  modded_tools_warning.visible = is_hiding_modded_shortcut
  modded_tools_warning.style.top_margin = 12
end

function ShortcutEditor:update()
  if not self.container then return end

  local shortcut_pages = self.container.shortcut_pages
  local page_count = 0
  for page in self.shortcut_slots:iter_visible_pages() do
    local page_button_frame = shortcut_pages.children[page.index]
    if page_button_frame then
      self:update_shortcut_slot_page(page_button_frame, page)
    else
      self:make_shortcut_slot_page(shortcut_pages, page)
    end
    page_count = page_count + 1
  end
  for i = #shortcut_pages.children, page_count + 1, -1 do
    shortcut_pages.children[i].destroy()
  end

  local hidden_button_table = self.container.hidden_button_frame.button_table
  local hidden_slot_count = 0
  local is_hiding_modded_shortcut = false
  for slot in self.shortcut_slots:iter_hidden_slots() do
    local slot_button = hidden_button_table.children[slot.index]
    if slot_button then
      self:update_shortcut_slot_button(slot_button, slot)
    else
      self:make_shortcut_slot_button(hidden_button_table, slot)
    end

    if slot.name then
      local shortcut = ShortcutDict.get(slot.name)
      if shortcut and shortcut.is_modded then
        is_hiding_modded_shortcut = true
      end
    end

    hidden_slot_count = hidden_slot_count + 1
  end
  for i = #hidden_button_table.children, hidden_slot_count + 1, -1 do
    hidden_button_table.children[i].destroy()
  end

  self.container.modded_tools_warning.visible = is_hiding_modded_shortcut
end

--- @return Customization
function ShortcutEditor:get_customization()
  return self.shortcut_slots:get_customization()
end

function ShortcutEditor:show_hiding_open_gui_error()
  self.player.create_local_flying_text({
    text = consts.str("hiding-open-gui-error"),
    create_at_cursor = true,
  })
end

function ShortcutEditor:show_hiding_toggleable_tool_error()
  self.player.create_local_flying_text({
    text = consts.str("hiding-toggleable-tool-error"),
    create_at_cursor = true,
  })
end

--- @param position ShortcutSlotPosition
--- @return boolean
function ShortcutEditor:toggle_visibility(position)
  local name = self.shortcut_slots:get_name_at(position)
  if not name then return false end
  local shortcut = ShortcutDict.get(name)
  if not shortcut then return false end

  if name == consts.OPEN_GUI_SHORTCUT_NAME then
    self:show_hiding_open_gui_error()
    return false
  end
  if shortcut.toggleable then
    self:show_hiding_toggleable_tool_error()
    return false
  end

  self.shortcut_slots:toggle_visibility(position)
  self:update()
  return true
end

--- @param name ShortcutName
--- @param to_position ShortcutSlotPosition
--- @return boolean
function ShortcutEditor:put_shortcut_into_slot(name, to_position)
  local from_position = self.shortcut_slots:get_position_of(name)
  if not from_position then return false end
  local shortcut = ShortcutDict.get(name)
  if not shortcut then return false end

  if self.shortcut_slots:is_hidden_position(to_position) then
    if name == consts.OPEN_GUI_SHORTCUT_NAME then
      self:show_hiding_open_gui_error()
      return false
    end
    if shortcut.toggleable then
      self:show_hiding_toggleable_tool_error()
      return false
    end
  end

  -- Swap shortcuts
  self.shortcut_slots:swap(from_position, to_position)
  self:update()
  return true
end

--- @param event EventData.on_gui_click
function ShortcutEditor:handle_shortcut_button_clicked(event)
  local tags = event.element.tags --[[@as ShortcutSlotButtonTags]]

  if event.button == defines.mouse_button_type.right then
    self:toggle_visibility(tags.slot_position)
    return
  end

  local cursor_stack = self.player.cursor_stack
  if not cursor_stack then return end

  if cursor_stack.valid_for_read then
    if cursor_stack.prototype.subgroup.name == consts.SHORTCUT_ITEM_SUBGROUP_NAME then
      -- Player is holding shortcut item
      local shortcut_name = string.sub(cursor_stack.name, #consts.SHORTCUT_ITEM_NAME_PREFIX + 1)
      if self:put_shortcut_into_slot(shortcut_name, tags.slot_position) then
        cursor_stack.clear()
      end
    end
    -- Any other item cannot be put into shortcut slots
    return
  end

  if tags.shortcut_name and tags.shortcut_name ~= "" then
    local shortcut = ShortcutDict.get(tags.shortcut_name)
    if shortcut then
      -- Hold the shortcut item
      cursor_stack.set_stack({ name = shortcut.item_name, count = 1 })
    end
  end
end

return ShortcutEditor
