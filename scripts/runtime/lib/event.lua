local Metatable = require("scripts.runtime.lib.metatable")

--- @class Event
local Event = {}

--- @alias EventType defines.events
--- @alias EventHandler fun(event: EventData)

--- @alias GuiEventType
--- | defines.events.on_gui_checked_state_changed
--- | defines.events.on_gui_click
--- | defines.events.on_gui_closed
--- | defines.events.on_gui_confirmed
--- | defines.events.on_gui_elem_changed
--- | defines.events.on_gui_hover
--- | defines.events.on_gui_leave
--- | defines.events.on_gui_location_changed
--- | defines.events.on_gui_opened
--- | defines.events.on_gui_selected_tab_changed
--- | defines.events.on_gui_selection_state_changed
--- | defines.events.on_gui_switch_state_changed
--- | defines.events.on_gui_text_changed
--- | defines.events.on_gui_value_changed

--- @alias GuiEventData
--- | EventData.on_gui_checked_state_changed
--- | EventData.on_gui_click
--- | EventData.on_gui_closed
--- | EventData.on_gui_confirmed
--- | EventData.on_gui_elem_changed
--- | EventData.on_gui_hover
--- | EventData.on_gui_leave
--- | EventData.on_gui_location_changed
--- | EventData.on_gui_opened
--- | EventData.on_gui_selected_tab_changed
--- | EventData.on_gui_selection_state_changed
--- | EventData.on_gui_switch_state_changed
--- | EventData.on_gui_text_changed
--- | EventData.on_gui_value_changed

--- @alias GuiEventHandler fun(event: GuiEventData)

--- @type table<EventType, table<EventHandler, boolean>>
local event_type_to_registered_handlers = {}

--- Register an event handler for the given event type.
---
--- If the event handler is already registered, it does nothing.
---
--- @param event_type EventType
--- @param handler EventHandler
function Event.register_event_handler(event_type, handler)
  local registered_handlers = event_type_to_registered_handlers[event_type]
  if not registered_handlers then
    registered_handlers = {}
    setmetatable(registered_handlers, Metatable.weak_key_metatable)
    event_type_to_registered_handlers[event_type] = registered_handlers
    script.on_event(event_type, Event.dispatch_event)
  end
  registered_handlers[handler] = true
end

--- Unregister an event handler.
---
--- @param handler EventHandler
function Event.unregister_event_handler(handler)
  for event_type, registered_handlers in pairs(event_type_to_registered_handlers) do
    registered_handlers[handler] = nil
    if not next(registered_handlers, nil) then
      event_type_to_registered_handlers[event_type] = nil
      script.on_event(event_type, nil)
    end
  end
end

--- Clear all registered event listeners.
function Event.clear_event_listeners()
  for event_type, _ in pairs(event_type_to_registered_handlers) do
    script.on_event(event_type, nil)
  end
  event_type_to_registered_handlers = {}
end

--- Dispatch an event to all registered handlers.
---
--- @param event EventData
function Event.dispatch_event(event)
  local handlers = event_type_to_registered_handlers[event.name]
  if handlers then
    local is_empty = true
    for handler in pairs(handlers) do
      handler(event)
      is_empty = false
    end
    if is_empty then
      -- It could be empty because it is a weak key table
      event_type_to_registered_handlers[event.name] = nil
      script.on_event(event.name, nil)
    end
  end
end

return Event
