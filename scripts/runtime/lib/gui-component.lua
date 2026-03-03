local consts = require("scripts.shared.consts")
local TableUtils = require("scripts.shared.table-utils")
local Event = require("scripts.runtime.lib.event")
local Metatable = require("scripts.runtime.lib.metatable")

--- @class GuiComponent
--- @field component_name string
--- @field handler_tag_prefix string
--- @field _event_handlers table<EventType, string>? Value is method name
local GuiComponent = {}

local HANDLER_TAG_PREFIX = consts.name("handler:")

--- A map from component instance to its event handler (bounded for self)
---
--- Because `store` serialization cannot serialize functions, we need to store it outside of component instance
--- @type table<GuiComponent, EventHandler>
local component_to_event_handler = {}
setmetatable(component_to_event_handler, Metatable.weak_key_metatable)

--- Define a new GuiComponent class
---
--- @generic T : GuiComponent
--- @param component_name string
--- @return T
function GuiComponent.define(component_name)
  local class = {
    component_name = component_name,
    handler_tag_prefix = HANDLER_TAG_PREFIX .. component_name .. ":",
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

  table = {
    [self.handle_gui_event] = "handle_gui_event",
  }
  for method_name, method in pairs(class) do
    if type(method) == "function" then
      table[method] = method_name
    end
  end
  class._method_name_table = table
  return table
end

--- @private
--- @return EventHandler
function GuiComponent:_get_event_handler()
  local handler = component_to_event_handler[self]
  if not handler then
    handler = function (event)
      local method_name = self._event_handlers[event.name]
      if method_name then
        self[method_name](self, event)
      end
    end
    component_to_event_handler[self] = handler
  end
  return handler
end

--- Set event listeners
---
--- Handlers are automatically bound to the component instance, so `self` in handlers will be the component instance.
---
--- If the event type is already listened, the handler will be overwritten.
---
--- @param handler_method_map table<EventType, EventHandler>
function GuiComponent:listen_to_events(handler_method_map)
  if not self._event_handlers then
    self._event_handlers = {}
  end

  local handler = self:_get_event_handler()
  local method_name_table = self:_get_method_name_table()
  for event_type, method in pairs(handler_method_map) do
    local method_name = method_name_table[method]
    if not method_name then
      error("Method not found for handler")
    end
    self._event_handlers[event_type] = method_name
    Event.register_event_handler(event_type, handler)
  end
end

--- @param event GuiEventData
function GuiComponent:handle_gui_event(event)
  local method_name = event.element.tags[self.handler_tag_prefix .. tostring(event.name)]
  if method_name then
    self[method_name](self, event)
  end
end

--- Set event listeners on a GUI element
---
--- Handlers are automatically bound to the component instance, so `self` in handlers will be the component instance.
---
--- @param element LuaGuiElement
--- @param handler_method_map table<GuiEventType, GuiEventHandler>
function GuiComponent:listen_to_gui_events(element, handler_method_map)
  local handler_map = {}
  local method_name_table = self:_get_method_name_table()
  local new_tags = TableUtils.shallow_copy(element.tags or {})
  for event_type, method in pairs(handler_method_map) do
    local method_name = method_name_table[method]
    if not method_name then
      error("Method not found for handler")
    end
    new_tags[self.handler_tag_prefix .. tostring(event_type)] = method_name
    handler_map[event_type] = self.handle_gui_event
  end
  self:listen_to_events(handler_map)
  element.tags = new_tags
end

--- Rebind all event listeners by this component
function GuiComponent:rebind_event_listeners()
  if not self._event_handlers then return end

  local handler = self:_get_event_handler()
  for event_type in pairs(self._event_handlers) do
    Event.register_event_handler(event_type, handler)
  end
end

--- Clear all event listeners by this component
---
--- Note: GUI elements remain having event handlers tag, so elements should be destroyed as well.
function GuiComponent:clear_event_listeners()
  if not self._event_handlers then return end

  local handler = self:_get_event_handler()
  Event.unregister_event_handler(handler)
  self._event_handlers = nil
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
