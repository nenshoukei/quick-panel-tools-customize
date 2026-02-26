--- Stage: runtime

local consts = require("scripts.consts")
local utils = require("scripts.utils")
local ShortcutDict = require("scripts.lib.shortcut-dict")

--- @class ShortcutSlots
--- @field name_to_position table<ShortcutName, ShortcutSlotPosition>
--- @field position_to_name table<ShortcutSlotPosition, ShortcutName>
local ShortcutSlots = {
  VISIBLE_SLOTS_PER_PAGE = 8,
  MINIMUM_VISIBLE_PAGE_COUNT = 4,
  HIDDEN_SLOTS_PER_ROW = 10,
}
ShortcutSlots.__index = ShortcutSlots
script.register_metatable(consts.name("ShortcutSlots"), ShortcutSlots)

--- For visible slots: `"v" .. index`
---
--- For hidden slots: `"h" .. index`
---
--- index should be padded with leading zeros to be sortable
--- @alias ShortcutSlotPosition string

--- @param visible boolean
--- @param index number
--- @return ShortcutSlotPosition
local function make_position(visible, index)
  return (visible and "v" or "h") .. ("%010d"):format(index)
end

--- @param position ShortcutSlotPosition
--- @return boolean visible
--- @return number index
local function describe_position(position)
  return position:sub(1, 1) == "v", assert(tonumber(position:sub(2)), "Invalid position: " .. position)
end

--- @class ShortcutSlots.SlotInfo
--- @field index number
--- @field name ShortcutName|nil
--- @field position ShortcutSlotPosition

--- @alias ShortcutSlots.SlotIterator fun(): ShortcutSlots.SlotInfo|nil

--- @class ShortcutSlots.VisibleSlotInfo : ShortcutSlots.SlotInfo
--- @field index_in_page number

--- @alias ShortcutSlots.VisibleSlotIterator fun(): ShortcutSlots.VisibleSlotInfo|nil

--- @class ShortcutSlots.VisiblePageInfo
--- @field index number
--- @field iter_slots fun(): ShortcutSlots.VisibleSlotIterator

--- @alias ShortcutSlots.VisiblePageIterator fun(): ShortcutSlots.VisiblePageInfo|nil

--- @return ShortcutSlots
function ShortcutSlots.new()
  return setmetatable({
    name_to_position = {},
    position_to_name = {},
  }, ShortcutSlots)
end

--- @param customization Customization
--- @return ShortcutSlots
function ShortcutSlots.new_with_customization(customization)
  local dict = ShortcutDict.get_from_prototypes()

  --- @type table<ShortcutName, ShortcutSlotPosition>
  local name_to_position = {}
  --- @type table<ShortcutSlotPosition, ShortcutName>
  local position_to_name = {}

  local next_visible_index = 1
  for i, name in ipairs(customization.shortcuts) do
    if name ~= "" and dict[name] then
      local position = make_position(true, i)
      name_to_position[name] = position
      position_to_name[position] = name
      next_visible_index = i + 1
    end
  end

  for i, name in ipairs(customization.hidden_shortcuts) do
    if name ~= "" and dict[name] then
      local position = make_position(false, i)
      name_to_position[name] = position
      position_to_name[position] = name
    end
  end

  -- New shortcuts
  for name, _ in pairs(dict) do
    if not name_to_position[name] then
      local position = make_position(true, next_visible_index)
      name_to_position[name] = position
      position_to_name[position] = name
      next_visible_index = next_visible_index + 1
    end
  end

  return setmetatable({
    name_to_position = name_to_position,
    position_to_name = position_to_name,
  }, ShortcutSlots)
end

--- @param position ShortcutSlotPosition
--- @return ShortcutName|nil
function ShortcutSlots:get_name_at(position)
  return self.position_to_name[position]
end

--- @param name ShortcutName
--- @return ShortcutSlotPosition|nil
function ShortcutSlots:get_position_of(name)
  return self.name_to_position[name]
end

--- @param from_position ShortcutSlotPosition
--- @param to_position ShortcutSlotPosition
function ShortcutSlots:swap(from_position, to_position)
  if from_position == to_position then return end

  local from_name = self.position_to_name[from_position]
  local to_name = self.position_to_name[to_position]
  if from_name == nil and to_name == nil then return end

  if from_name then
    self.name_to_position[from_name] = to_position
  end
  if to_name then
    self.name_to_position[to_name] = from_position
  end

  self.position_to_name[from_position] = to_name
  self.position_to_name[to_position] = from_name
end

--- @private
--- @param visible boolean
--- @return ShortcutSlotPosition
function ShortcutSlots:get_first_empty_slot_position(visible)
  local index = 1
  while true do
    local position = make_position(visible, index)
    if not self.position_to_name[position] then
      return position
    end
    index = index + 1
  end
end

--- @param position ShortcutSlotPosition
--- @return ShortcutSlotPosition|nil new_position
function ShortcutSlots:toggle_visibility(position)
  local name = self.position_to_name[position]
  if not name then return nil end

  local visible = describe_position(position)
  local to_position = self:get_first_empty_slot_position(not visible)
  self.name_to_position[name] = to_position
  self.position_to_name[to_position] = name
  self.position_to_name[position] = nil
  return to_position
end

--- @private
--- @param visible boolean
--- @return number
function ShortcutSlots:get_least_slot_count(visible)
  local max_index = 0
  for _, position in pairs(self.name_to_position) do
    local pos_visible, pos_index = describe_position(position)
    if pos_visible == visible then
      max_index = math.max(max_index, pos_index)
    end
  end
  return max_index + 1 -- Always have one empty slot at the end
end

--- @return ShortcutSlots.VisiblePageIterator
function ShortcutSlots:iter_visible_pages()
  local least_count = self:get_least_slot_count(true)
  local page_count = math.max(self.MINIMUM_VISIBLE_PAGE_COUNT,
    math.ceil(least_count / self.VISIBLE_SLOTS_PER_PAGE))
  local page_index = 1

  --- @return ShortcutSlots.VisiblePageInfo|nil
  return function ()
    if page_index > page_count then
      return nil
    end

    local this_page_index = page_index
    page_index = page_index + 1

    return {
      index = this_page_index,
      iter_slots = function ()
        local slot_index = (this_page_index - 1) * self.VISIBLE_SLOTS_PER_PAGE + 1
        local slot_index_in_page = 1

        return function ()
          if slot_index_in_page > self.VISIBLE_SLOTS_PER_PAGE then
            return nil
          end

          local position = make_position(true, slot_index)

          --- @type ShortcutSlots.VisibleSlotInfo
          local slot_info = {
            index = slot_index,
            index_in_page = slot_index_in_page,
            name = self.position_to_name[position],
            position = position,
          }

          slot_index = slot_index + 1
          slot_index_in_page = slot_index_in_page + 1
          return slot_info
        end
      end,
    }
  end
end

--- @return ShortcutSlots.SlotIterator
function ShortcutSlots:iter_hidden_slots()
  local least_count = self:get_least_slot_count(false)
  local slot_count = math.ceil(least_count / self.HIDDEN_SLOTS_PER_ROW) * self.HIDDEN_SLOTS_PER_ROW
  local slot_index = 1

  --- @return ShortcutSlots.SlotInfo|nil
  return function ()
    if slot_index > slot_count then
      return nil
    end

    local position = make_position(false, slot_index)

    --- @type ShortcutSlots.SlotInfo
    local slot_info = {
      index = slot_index,
      name = self.position_to_name[position],
      position = position,
    }

    slot_index = slot_index + 1
    return slot_info
  end
end

--- @return Customization
function ShortcutSlots:get_customization()
  --- @type ShortcutName[]
  local shortcuts = {}
  --- @type ShortcutName[]
  local hidden_shortcuts = {}

  local positions = utils.table_keys(self.position_to_name)
  table.sort(positions)

  local last_visible_index = 0
  for _, position in ipairs(positions) do
    local visible, index = describe_position(position)
    if visible then
      if index > last_visible_index + 1 then
        -- Fill the gap with placeholder slots
        for i = last_visible_index + 1, index - 1 do
          shortcuts[i] = ""
        end
      end
      shortcuts[index] = self.position_to_name[position]
      last_visible_index = index
    else
      hidden_shortcuts[#hidden_shortcuts + 1] = self.position_to_name[position]
    end
  end

  return {
    shortcuts = shortcuts,
    hidden_shortcuts = hidden_shortcuts,
  }
end

return ShortcutSlots
