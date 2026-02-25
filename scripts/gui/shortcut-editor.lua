local consts = require("scripts.consts")
local utils = require("scripts.utils")
local GuiComponent = require("scripts.lib.gui-component")
local ShortcutDict = require("scripts.lib.shortcut-dict")
local ShortcutSlots = require("scripts.lib.shortcut-slots")
local GuiParts = require("scripts.gui.gui-parts")

local ShortcutEditor = {}

--- @class ShortcutSlotButtonTags
--- @field shortcut_name ShortcutName|nil
--- @field slot_position ShortcutSlotPosition

--- @class ShortcutEditor : GuiComponent
--- @field player LuaPlayer
--- @field shortcut_slots ShortcutSlots
--- @field container LuaGuiElement|nil
local ShortcutEditorMethods = {}

local metatable = GuiComponent.define("ShortcutEditor", ShortcutEditorMethods)

--- @param self ShortcutEditor
--- @return ShortcutEditor
function ShortcutEditor.setmetatable(self)
  return setmetatable(self, metatable)
end

--- @param player LuaPlayer
--- @param customization Customization
--- @return ShortcutEditor
function ShortcutEditor.new(player, customization)
  return ShortcutEditor.setmetatable({
    player = player,
    shortcut_slots = ShortcutSlots.new_with_customization(customization),
  })
end

function ShortcutEditorMethods:on_load()
  ShortcutSlots.setmetatable(self.shortcut_slots)

  if self.container then
    -- Remove old GUI elements
    self:destroy()
  end
end

function ShortcutEditorMethods:on_destroy()
  if self.container then
    self.container.destroy()
    self.container = nil
  end
end

--- @param customization Customization
function ShortcutEditorMethods:reload(customization)
  self.shortcut_slots = ShortcutSlots.new_from_customization(customization)
end

--- @param parent LuaGuiElement
--- @param slot ShortcutSlots.SlotInfo
--- @return LuaGuiElement
function ShortcutEditorMethods:make_shortcut_slot_button(parent, slot)
  --- @type ShortcutSlotButtonTags
  local tags = {
    shortcut_name = slot.name,
    slot_position = slot.position,
  }

  local button
  if slot.name then
    local dict = ShortcutDict.get_from_prototypes()
    local shortcut = dict[slot.name]
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

  self:listen_events(button, {
    [defines.events.on_gui_click] = self.handle_shortcut_button_clicked,
  })

  return button
end

--- @param button LuaGuiElement
--- @param slot ShortcutSlots.SlotInfo
function ShortcutEditorMethods:update_shortcut_slot_button(button, slot)
  local tags = button.tags --[[@as ShortcutSlotButtonTags]]
  if tags.shortcut_name == slot.name then
    return
  end

  --- @type ShortcutSlotButtonTags
  button.tags = utils.table_merge(button.tags, {
    shortcut_name = slot.name,
    slot_position = slot.position,
  })

  if slot.name then
    local dict = ShortcutDict.get_from_prototypes()
    local shortcut = dict[slot.name]
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

--- @param parent LuaGuiElement
--- @param page ShortcutSlots.VisiblePageInfo
--- @return LuaGuiElement
function ShortcutEditorMethods:make_shortcut_slot_page(parent, page)
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

--- @param page_button_frame LuaGuiElement
--- @param page ShortcutSlots.VisiblePageInfo
function ShortcutEditorMethods:update_shortcut_slot_page(page_button_frame, page)
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
function ShortcutEditorMethods:render(parent)
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
    column_count = 6,
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
  for slot in self.shortcut_slots:iter_hidden_slots() do
    self:make_shortcut_slot_button(hidden_button_table, slot)
  end
end

function ShortcutEditorMethods:update()
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
  for slot in self.shortcut_slots:iter_hidden_slots() do
    local slot_button = hidden_button_table.children[slot.index]
    if slot_button then
      self:update_shortcut_slot_button(slot_button, slot)
    else
      self:make_shortcut_slot_button(hidden_button_table, slot)
    end
    hidden_slot_count = hidden_slot_count + 1
  end
  for i = #hidden_button_table.children, hidden_slot_count + 1, -1 do
    hidden_button_table.children[i].destroy()
  end
end

--- @return Customization
function ShortcutEditorMethods:get_customization()
  return self.shortcut_slots:get_customization()
end

--- @param event EventData.on_gui_click
function ShortcutEditorMethods:handle_shortcut_button_clicked(event)
  local tags = event.element.tags --[[@as ShortcutSlotButtonTags]]

  if event.button == defines.mouse_button_type.right then
    self.shortcut_slots:toggle_visibility(tags.slot_position)
    self:update()
    return
  end

  if self.player.cursor_stack and self.player.cursor_stack.valid_for_read then
    if self.player.cursor_stack.prototype.subgroup.name == consts.SHORTCUT_ITEM_SUBGROUP_NAME then
      -- Player is holding shortcut item
      local shortcut_name = string.sub(self.player.cursor_stack.name, #consts.SHORTCUT_ITEM_NAME_PREFIX + 1)
      local from_position = self.shortcut_slots:get_position_of(shortcut_name)
      if from_position then
        -- Swap holding shortcut item slot with clicked slot
        self.shortcut_slots:swap(from_position, tags.slot_position)
        self.player.cursor_stack.clear()
        self:update()
        return
      end
    end
    -- Any other item cannot be put into shortcut slots
    return
  end

  if tags.shortcut_name then
    local dict = ShortcutDict.get_from_prototypes()
    local shortcut = dict[tags.shortcut_name] --[[@as ShortcutDictEntry]]
    if shortcut then
      -- Hold the shortcut item
      self.player.cursor_stack.set_stack({ name = shortcut.item_name, count = 1 })
    end
  end
end

return ShortcutEditor
