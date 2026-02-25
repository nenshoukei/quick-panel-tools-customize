--- Stage: runtime

local consts = require("scripts.consts")
local ShortcutDict = require("scripts.lib.shortcut-dict")

local ShortcutSlots = {
  VISIBLE_SLOTS_PER_PAGE = 8,
  MINIMUM_VISIBLE_PAGE_COUNT = 4,
  HIDDEN_SLOTS_PER_ROW = 20,
}

--- For visible slots: `"v" .. index`
---
--- For hidden slots: `"h" .. index`
--- @alias ShortcutSlotPosition string

--- @param visible boolean
--- @param index number
--- @return ShortcutSlotPosition
local function make_position(visible, index)
  return visible and "v" .. index or "h" .. index
end

--- @param position ShortcutSlotPosition
--- @return boolean visible
--- @return number index
local function describe_position(position)
  return position:sub(1, 1) == "v", assert(tonumber(position:sub(2)))
end

--- @class ShortcutSlots
--- @field name_to_position table<ShortcutName, ShortcutSlotPosition>
--- @field position_to_name table<ShortcutSlotPosition, ShortcutName>
local ShortcutSlotsMethods = {}

local metatable = { __index = ShortcutSlotsMethods }
script.register_metatable(consts.name("ShortcutSlots"), metatable)

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

--- @param self ShortcutSlots
--- @return ShortcutSlots
function ShortcutSlots.setmetatable(self)
  return setmetatable(self, metatable)
end

--- @return ShortcutSlots
function ShortcutSlots.new()
  return ShortcutSlots.setmetatable({
    name_to_position = {},
    position_to_name = {},
  })
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

  return ShortcutSlots.setmetatable({
    name_to_position = name_to_position,
    position_to_name = position_to_name,
  })
end

--- @param position ShortcutSlotPosition
--- @return ShortcutName|nil
function ShortcutSlotsMethods:get_name_at(position)
  return self.position_to_name[position]
end

--- @param name ShortcutName
--- @return ShortcutSlotPosition|nil
function ShortcutSlotsMethods:get_position_of(name)
  return self.name_to_position[name]
end

--- @param from_position ShortcutSlotPosition
--- @param to_position ShortcutSlotPosition
function ShortcutSlotsMethods:swap(from_position, to_position)
  if from_position == to_position then return end

  local from_name = self.position_to_name[from_position]
  local to_name = self.position_to_name[to_position]
  self.name_to_position[from_name] = to_position
  self.name_to_position[to_name] = from_position
  self.position_to_name[from_position] = to_name
  self.position_to_name[to_position] = from_name
end

--- @private
--- @param visible boolean
--- @return number
function ShortcutSlotsMethods:get_next_index_for_visibility(visible)
  local last_index = 0
  for _, position in pairs(self.name_to_position) do
    if describe_position(position).visible == visible then
      last_index = math.max(last_index, position.index)
    end
  end
  return last_index + 1
end

--- @param position ShortcutSlotPosition
--- @return ShortcutSlotPosition|nil new_position
function ShortcutSlotsMethods:toggle_visibility(position)
  local name = self.position_to_name[position]
  if not name then return nil end

  local to_index = self:get_next_index_for_visibility(not position.visible)
  local to_position = make_position(not position.visible, to_index)
  self.name_to_position[name] = to_position
  self.position_to_name[to_position] = name
  self.position_to_name[position] = nil
  return to_position
end

--- @return ShortcutSlots.VisiblePageIterator
function ShortcutSlotsMethods:iter_visible_pages()
  local next_index = self:get_next_index_for_visibility(true)
  local page_count = math.max(ShortcutSlots.MINIMUM_VISIBLE_PAGE_COUNT,
    math.ceil(next_index / ShortcutSlots.VISIBLE_SLOTS_PER_PAGE))
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
        local slot_index = (this_page_index - 1) * ShortcutSlots.VISIBLE_SLOTS_PER_PAGE + 1
        local slot_index_in_page = 1

        return function ()
          if slot_index_in_page > ShortcutSlots.VISIBLE_SLOTS_PER_PAGE then
            return nil
          end

          --- @type ShortcutSlotPosition
          local position = { visible = true, index = slot_index }

          --- @type ShortcutSlots.VisibleSlotInfo
          local slot_info = {
            index = slot_index,
            index_in_page = slot_index_in_page,
            name = self.key_to_name[position_to_key(position)],
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
function ShortcutSlotsMethods:iter_hidden_slots()
  local next_index = self:get_next_index_for_visibility(false)
  local slot_count = math.ceil(next_index / ShortcutSlots.HIDDEN_SLOTS_PER_ROW) * ShortcutSlots.HIDDEN_SLOTS_PER_ROW
  local slot_index = 1

  --- @return ShortcutSlots.SlotInfo|nil
  return function ()
    if slot_index > slot_count then
      return nil
    end

    --- @type ShortcutSlots.SlotInfo
    local slot_info = {
      index = slot_index,
      name = nil,
      position = { visible = false, index = slot_index },
    }

    local name = self.key_to_name[position_to_key(slot_info.position)]
    if name then
      slot_info.name = name
    end

    slot_index = slot_index + 1
    return slot_info
  end
end

--- @return Customization
function ShortcutSlotsMethods:get_customization()
  --- @type ShortcutName[]
  local shortcuts = {}
  --- @type ShortcutName[]
  local hidden_shortcuts = {}

  local last_visible_index = 0
  for name, position in pairs(self.name_to_position) do
    if position.visible then
      if position.index > last_visible_index + 1 then
        -- We should fill the gap with placeholder slots
        for i = last_visible_index + 1, position.index - 1 do
          shortcuts[i] = ""
        end
        last_visible_index = position.index
      end
      shortcuts[position.index] = name
    else
      table.insert(hidden_shortcuts, name)
    end
  end

  -- Keep hidden shortcuts order
  table.sort(hidden_shortcuts, function (a, b)
    return self.name_to_position[a].index < self.name_to_position[b].index
  end)

  return {
    shortcuts = shortcuts,
    hidden_shortcuts = hidden_shortcuts,
  }
end

return ShortcutSlots
