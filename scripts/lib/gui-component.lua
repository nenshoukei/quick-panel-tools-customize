--- Stage: runtime

local consts = require("scripts.consts")
local utils = require("scripts.utils")
local Event = require("scripts.lib.event")
local Metatable = require("scripts.lib.metatable")

--- @class GuiComponent
--- @field component_name string
--- @field handler_tag_prefix string
local GuiComponent = {}

--- @alias GuiComponentEventHandler fun(self: GuiComponent, event: GuiEventData)

local HANDLER_TAG_PREFIX = "handler_"

--- To avoid serialization, we need to store handlers outside of component instance
--- @type table<GuiComponent, GuiEventHandler>
local component_to_handler_map = {}
setmetatable(component_to_handler_map, Metatable.weak_key_metatable)

--- Define a new GuiComponent class
---
--- @generic T : GuiComponent
--- @param component_name string
--- @return T
function GuiComponent.define(component_name)
  local class = {
    component_name = component_name,
    handler_tag_prefix = HANDLER_TAG_PREFIX .. component_name .. "_",
  }
  class.__index = function (self, key)
    return class[key] or GuiComponent[key]
  end
  script.register_metatable(consts.name(component_name), class)
  return class
end

--- @private
--- @return table<function, string>
function GuiComponent:_get_method_name_table()
  local class = getmetatable(self)
  local table = class._method_name_table
  if table then return table end

  table = {}
  for method_name, method in pairs(class) do
    if type(method) == "function" then
      table[method] = method_name
    end
  end
  class._method_name_table = table
  return table
end

--- @private
--- @return GuiEventHandler
function GuiComponent:_get_event_handler()
  local handler = component_to_handler_map[self]
  if not handler then
    handler = function (event)
      local method_name = event.element.tags[self.handler_tag_prefix .. tostring(event.name)]
      if method_name then
        self[method_name](self, event)
      end
    end
    component_to_handler_map[self] = handler
  end
  return handler
end

--- Set event listeners on a GUI element
---
--- Handlers are automatically bound to the component instance, so `self` in handlers will be the component instance.
---
--- @param element LuaGuiElement
--- @param handler_method_map table<GuiEventType, GuiComponentEventHandler>
function GuiComponent:listen_to_gui_events(element, handler_method_map)
  local handler = self:_get_event_handler()
  local method_name_table = self:_get_method_name_table()
  local new_tags = utils.table_shallow_copy(element.tags or {})
  for event_type, method in pairs(handler_method_map) do
    local method_name = method_name_table[method]
    if not method_name then
      error("Method not found for handler")
    end
    new_tags[self.handler_tag_prefix .. tostring(event_type)] = method_name
    Event.register_event_handler(event_type, handler)
  end
  element.tags = new_tags

  if not self._listening_elements then
    self._listening_elements = {}
    setmetatable(self._listening_elements, Metatable.weak_key_metatable)
  end
  self._listening_elements[element] = true
end

--- Rebind all event listeners by this component
function GuiComponent:rebind_event_listeners()
  if not self._listening_elements then return end

  local handler = self:_get_event_handler()
  for element in pairs(self._listening_elements) do
    if element.valid then
      for tag_name in pairs(element.tags) do
        if tag_name:sub(1, #self.handler_tag_prefix) == self.handler_tag_prefix then
          local event_type = tonumber(tag_name:sub(#self.handler_tag_prefix + 1)) --[[@as defines.events]]
          Event.register_event_handler(event_type, handler)
        end
      end
    else
      self._listening_elements[element] = nil
    end
  end
end

--- Clear all event listeners by this component
---
--- Note: GUI elements remain having event handlers tag, so elements should be destroyed as well.
function GuiComponent:clear_event_listeners()
  local handler = component_to_handler_map[self]
  if not handler then return end

  Event.unregister_event_handler(handler)
  component_to_handler_map[self] = nil

  self._listening_elements = nil
end

--- Load the component
---
--- This should be called on LuaBootstrap::on_load
function GuiComponent:load()
  self:rebind_event_listeners()
end

--- Destroy the component
---
--- This should be called when this component is no longer needed
function GuiComponent:destroy()
  self:clear_event_listeners()
end

return GuiComponent
