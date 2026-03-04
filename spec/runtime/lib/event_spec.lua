--- @diagnostic disable: missing-fields
local Event = require("scripts.runtime.lib.event")
local helper = require("spec.helper")
local spy = require("luassert.spy")

describe("Event", function ()
  --- @type luassert.spy
  local spy_on_event

  setup(function ()
    helper.reset_mocks()
  end)

  before_each(function ()
    spy_on_event = spy.new(function () end)
    _G.script.on_event = spy_on_event

    -- Clear Event module cache
    package.loaded["scripts.runtime.lib.event"] = nil
    Event = require("scripts.runtime.lib.event")
  end)

  describe("register_event_handler", function ()
    it("registers first handler for event type", function ()
      local test_handler = spy.new(function () end)
      Event.register_event_handler(defines.events.on_gui_click, test_handler --[[@as EventHandler]])

      assert.spy(spy_on_event).was.called_with(defines.events.on_gui_click, Event.dispatch_event)

      local event_data = { name = defines.events.on_gui_click }
      Event.dispatch_event(event_data --[[@as EventData]])

      assert.spy(test_handler).was.called_with(event_data)
    end)

    it("registers multiple handlers for same event type", function ()
      local handler1 = spy.new(function () end)
      local handler2 = spy.new(function () end)

      Event.register_event_handler(defines.events.on_gui_click, handler1 --[[@as EventHandler]])
      Event.register_event_handler(defines.events.on_gui_click, handler2 --[[@as EventHandler]])

      Event.dispatch_event({ name = defines.events.on_gui_click })

      assert.spy(handler1).was.called(1)
      assert.spy(handler2).was.called(1)
    end)

    it("registers handlers for different event types", function ()
      local click_handler = spy.new(function () end)
      local close_handler = spy.new(function () end)

      Event.register_event_handler(defines.events.on_gui_click, click_handler --[[@as EventHandler]])
      Event.register_event_handler(defines.events.on_gui_closed, close_handler --[[@as EventHandler]])

      assert.spy(spy_on_event).was.called_with(defines.events.on_gui_click, Event.dispatch_event)
      assert.spy(spy_on_event).was.called_with(defines.events.on_gui_closed, Event.dispatch_event)

      Event.dispatch_event({ name = defines.events.on_gui_click })
      Event.dispatch_event({ name = defines.events.on_gui_closed })

      assert.spy(click_handler).was.called(1)
      assert.spy(close_handler).was.called(1)
    end)

    it("does not register duplicate handler", function ()
      local test_handler = spy.new(function () end)

      Event.register_event_handler(defines.events.on_gui_click, test_handler --[[@as EventHandler]])
      Event.register_event_handler(defines.events.on_gui_click, test_handler --[[@as EventHandler]])

      assert.spy(spy_on_event).was.called(1)

      Event.dispatch_event({ name = defines.events.on_gui_click })

      assert.spy(test_handler).was.called(1)
    end)
  end)

  describe("unregister_event_handler", function ()
    it("unregisters handler from single event type", function ()
      local test_handler = spy.new(function () end)

      Event.register_event_handler(defines.events.on_gui_click, test_handler --[[@as EventHandler]])
      spy_on_event:clear()

      Event.unregister_event_handler(test_handler --[[@as EventHandler]])
      assert.spy(spy_on_event).was.called_with(defines.events.on_gui_click, nil)

      Event.dispatch_event({ name = defines.events.on_gui_click })

      assert.spy(test_handler).was.called(0)
    end)

    it("unregisters handler from multiple event types", function ()
      local test_handler = spy.new(function () end)

      Event.register_event_handler(defines.events.on_gui_click, test_handler --[[@as EventHandler]])
      Event.register_event_handler(defines.events.on_gui_closed, test_handler --[[@as EventHandler]])
      spy_on_event:clear()

      Event.unregister_event_handler(test_handler --[[@as EventHandler]])
      assert.spy(spy_on_event).was.called_with(defines.events.on_gui_click, nil)
      assert.spy(spy_on_event).was.called_with(defines.events.on_gui_closed, nil)

      Event.dispatch_event({ name = defines.events.on_gui_click })
      Event.dispatch_event({ name = defines.events.on_gui_closed })

      -- Handler should not be called for either event
      assert.spy(test_handler).was.called(0)
    end)

    it("removes script.on_event when no handlers remain", function ()
      local handler1 = function () end
      local handler2 = function () end

      Event.register_event_handler(defines.events.on_gui_click, handler1)
      Event.register_event_handler(defines.events.on_gui_click, handler2)
      spy_on_event:clear()

      Event.unregister_event_handler(handler1)
      assert.spy(spy_on_event).was.called(0)

      Event.unregister_event_handler(handler2)
      assert.spy(spy_on_event).was.called_with(defines.events.on_gui_click, nil)
    end)

    it("does not unregister other handlers", function ()
      local handler1 = spy.new(function () end)
      local handler2 = spy.new(function () end)

      Event.register_event_handler(defines.events.on_gui_click, handler1 --[[@as EventHandler]])
      Event.register_event_handler(defines.events.on_gui_click, handler2 --[[@as EventHandler]])
      Event.unregister_event_handler(handler1 --[[@as EventHandler]])

      Event.dispatch_event({ name = defines.events.on_gui_click })

      assert.spy(handler1).was.called(0)
      assert.spy(handler2).was.called(1)
    end)

    it("handles unregistering non-existent handler gracefully", function ()
      local test_handler = function () end

      assert.no_error(function ()
        Event.unregister_event_handler(test_handler)
      end)
    end)
  end)

  describe("clear_event_listeners", function ()
    it("unregisters all event handlers", function ()
      local handler1 = spy.new(function () end)
      local handler2 = spy.new(function () end)

      Event.register_event_handler(defines.events.on_gui_click, handler1 --[[@as EventHandler]])
      Event.register_event_handler(defines.events.on_gui_closed, handler2 --[[@as EventHandler]])
      spy_on_event:clear()

      Event.clear_event_listeners()

      assert.spy(spy_on_event).was.called(2)
      assert.spy(spy_on_event).was.called_with(defines.events.on_gui_click, nil)
      assert.spy(spy_on_event).was.called_with(defines.events.on_gui_closed, nil)

      Event.dispatch_event({ name = defines.events.on_gui_click })
      Event.dispatch_event({ name = defines.events.on_gui_closed })

      assert.spy(handler1).was.called(0)
      assert.spy(handler2).was.called(0)
    end)
  end)

  describe("dispatch_event", function ()
    it("calls registered handlers with event data", function ()
      local test_handler = spy.new(function () end)

      Event.register_event_handler(defines.events.on_gui_click, test_handler --[[@as EventHandler]])

      local event_data = {
        name = defines.events.on_gui_click,
        player_index = 1,
        element = { name = "test-button" },
      }
      Event.dispatch_event(event_data --[[@as EventData]])

      assert.spy(test_handler).was.called(1)
      assert.spy(test_handler).was.called_with(event_data)
    end)

    it("does not call handlers for different event types", function ()
      local test_handler = spy.new(function () end)

      Event.register_event_handler(defines.events.on_gui_click, test_handler --[[@as EventHandler]])

      -- Dispatch different event type
      Event.dispatch_event({ name = defines.events.on_gui_closed })

      assert.spy(test_handler).was.called(0)
    end)

    it("handles dispatch to no registered handlers", function ()
      assert.no_error(function ()
        Event.dispatch_event({ name = defines.events.on_gui_click })
      end)
    end)
  end)

  describe("weak key behavior", function ()
    it("allows garbage collection of handlers", function ()
      local call_count = 0
      do
        local test_handler = function () call_count = call_count + 1 end
        Event.register_event_handler(defines.events.on_gui_click, test_handler)

        -- Dispatch event to verify handler works
        Event.dispatch_event({ name = defines.events.on_gui_click })
        assert.are_equal(1, call_count)
      end

      call_count = 0

      -- test_handler should be eligible for garbage collection
      -- Force garbage collection (though this is not guaranteed)
      collectgarbage("collect")

      -- Dispatch event again
      Event.dispatch_event({ name = defines.events.on_gui_click })

      assert.are_equal(0, call_count)

      -- Empty handler should be removed
      assert.spy(spy_on_event).was.called_with(defines.events.on_gui_click, nil)
    end)
  end)

  describe("integration", function ()
    it("handles register/unregister/dispatch cycle", function ()
      local test_handler = spy.new(function () end)

      -- Register handler
      Event.register_event_handler(defines.events.on_gui_click, test_handler --[[@as EventHandler]])

      -- Dispatch event
      local event_data = { name = defines.events.on_gui_click }
      Event.dispatch_event(event_data --[[@as EventData]])
      assert.spy(test_handler).was.called(1)

      -- Unregister handler
      Event.unregister_event_handler(test_handler --[[@as EventHandler]])

      -- Dispatch event again
      Event.dispatch_event(event_data --[[@as EventData]])
      assert.spy(test_handler).was.called(1)

      -- Register again
      Event.register_event_handler(defines.events.on_gui_click, test_handler --[[@as EventHandler]])

      -- Dispatch event again
      Event.dispatch_event(event_data --[[@as EventData]])
      assert.spy(test_handler).was.called(2)
    end)

    it("handles multiple event types with different handlers", function ()
      local click_handler = spy.new(function () end)
      local close_handler = spy.new(function () end)
      local open_handler = spy.new(function () end)

      Event.register_event_handler(defines.events.on_gui_click, click_handler --[[@as EventHandler]])
      Event.register_event_handler(defines.events.on_gui_closed, close_handler --[[@as EventHandler]])
      Event.register_event_handler(defines.events.on_gui_opened, open_handler --[[@as EventHandler]])

      -- Dispatch events in different order
      Event.dispatch_event({ name = defines.events.on_gui_opened })
      Event.dispatch_event({ name = defines.events.on_gui_click })
      Event.dispatch_event({ name = defines.events.on_gui_closed })

      assert.spy(open_handler).was.called(1)
      assert.spy(click_handler).was.called(1)
      assert.spy(close_handler).was.called(1)
    end)
  end)
end)
