--- Stage: runtime

local utils = require("scripts.utils")

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

--- @type table<GuiEventType, boolean>
local gui_events = {
  [defines.events.on_gui_checked_state_changed] = true,
  [defines.events.on_gui_click] = true,
  [defines.events.on_gui_closed] = true,
  [defines.events.on_gui_confirmed] = true,
  [defines.events.on_gui_elem_changed] = true,
  [defines.events.on_gui_hover] = true,
  [defines.events.on_gui_leave] = true,
  [defines.events.on_gui_location_changed] = true,
  [defines.events.on_gui_opened] = true,
  [defines.events.on_gui_selected_tab_changed] = true,
  [defines.events.on_gui_selection_state_changed] = true,
  [defines.events.on_gui_switch_state_changed] = true,
  [defines.events.on_gui_text_changed] = true,
  [defines.events.on_gui_value_changed] = true,
}

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

--- @type table<EventHandler, number>
local handler_to_id_map = {}

--- @type table<number, EventHandler>
local id_to_handler_map = {}

--- @type table<EventType, table<EventHandler, boolean>>
local event_type_to_handlers_map = {}

--- @type uint
local next_handler_id = 1

local HANDLER_ID_TAG_PREFIX = "handler_id_"

--- @param event_type EventType
--- @param handler EventHandler
--- @return uint handler_id
function Event.add_event_handler(event_type, handler)
  local handler_id = handler_to_id_map[handler]
  if not handler_id then
    handler_id = next_handler_id
    next_handler_id = next_handler_id + 1
    handler_to_id_map[handler] = handler_id
    id_to_handler_map[handler_id] = handler

    if event_type_to_handlers_map[event_type] then
      event_type_to_handlers_map[event_type][handler] = true
    else
      event_type_to_handlers_map[event_type] = { [handler] = true }
      script.on_event(event_type, gui_events[event_type] and Event.dispatch_gui_event or Event.dispatch_event)
    end
  end
  return handler_id
end

--- @param element LuaGuiElement
--- @param event_type GuiEventType
--- @param handler GuiEventHandler
function Event.add_event_handler_on_element(element, event_type, handler)
  local handler_id = Event.add_event_handler(event_type, handler)
  element.tags = utils.table_merge(element.tags or {}, {
    [HANDLER_ID_TAG_PREFIX .. tostring(event_type)] = handler_id,
  })
end

--- @param handler EventHandler
function Event.remove_event_handler(handler)
  local handler_id = handler_to_id_map[handler]
  if handler_id then
    handler_to_id_map[handler] = nil
    id_to_handler_map[handler_id] = nil

    for event_type, handlers in pairs(event_type_to_handlers_map) do
      handlers[handler] = nil
      if not next(handlers, nil) then
        event_type_to_handlers_map[event_type] = nil
        script.on_event(event_type, nil)
      end
    end
  end
end

--- @param event EventData
function Event.dispatch_event(event)
  local handlers = event_type_to_handlers_map[event.name]
  if handlers then
    for handler in pairs(handlers) do
      handler(event)
    end
  end
end

--- @param event GuiEventData
function Event.dispatch_gui_event(event)
  local handler_id = event.element.tags[HANDLER_ID_TAG_PREFIX .. tostring(event.name)]
  if handler_id then
    local handler = id_to_handler_map[handler_id]
    if handler then
      handler(event)
    end
  end
end

return Event
