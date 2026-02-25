local consts = require("scripts.consts")
local Event = require("scripts.lib.event")

local GuiComponent = {}

--- @class GuiComponent
--- @field on_destroy fun(self: GuiComponent)?
local GuiComponentMethods = {}

--- @generic T : GuiComponent
--- @alias GuiComponentEventHandler<T> fun(self: T, event: GuiEventData)

--- @type table<GuiComponentEventHandler, GuiEventHandler>
local bound_handler_map = {}
setmetatable(bound_handler_map, { __mode = "k" }) -- Make it weak reference key

--- @type table<GuiComponent, table<GuiComponentEventHandler, boolean>>
local component_to_handler_set = {}
setmetatable(component_to_handler_set, { __mode = "k" })

--- Define a new GuiComponent
---
--- Stage: runtime
---
--- @param component_name string
--- @param methods table<string, function>
--- @return table metatable
function GuiComponent.define(component_name, methods)
  local metatable = {
    __index = function (tbl, key)
      return methods[key] or GuiComponentMethods[key]
    end,
  }
  script.register_metatable(consts.name(component_name), metatable)
  return metatable
end

--- Listen to events on a GUI element
---
--- @param element LuaGuiElement
--- @param handler_map table<GuiEventType, GuiComponentEventHandler>
function GuiComponentMethods:listen_events(element, handler_map)
  local event_handlers = {}
  for event_type, handler in pairs(handler_map) do
    local bound_handler = bound_handler_map[handler]
    if not bound_handler then
      bound_handler = function (event)
        handler(self, event)
      end
      bound_handler_map[handler] = bound_handler
    end

    local handler_set = component_to_handler_set[self]
    if handler_set then
      handler_set[handler] = true
    else
      component_to_handler_set[self] = { [handler] = true }
    end

    event_handlers[event_type] = bound_handler
  end
  Event.set_event_handlers_on_gui_element(element, event_handlers)
end

--- Clear all event listeners on this component
function GuiComponentMethods:clear_all_event_listeners()
  local handler_set = component_to_handler_set[self]
  if not handler_set then return end

  for handler, _ in pairs(handler_set) do
    local bound_handler = bound_handler_map[handler]
    if bound_handler then
      Event.unregister_event_handler(bound_handler)
    end
    bound_handler_map[handler] = nil
  end
  component_to_handler_set[self] = nil
end

--- Destroy this component
function GuiComponentMethods:destroy()
  self:clear_all_event_listeners()
  if self.on_destroy then
    self:on_destroy()
  end
end

return GuiComponent
