--- @diagnostic disable: missing-fields
local GuiComponent = require("scripts.runtime.lib.gui-component")
local Event = require("scripts.runtime.lib.event")
local helper = require("spec.helper")
local spy = require("luassert.spy")

describe("GuiComponent", function ()
  setup(function ()
    helper.reset_mocks()
  end)

  before_each(function ()
    Event.clear_event_listeners()

    -- Clear GuiComponent module cache
    package.loaded["scripts.runtime.lib.gui-component"] = nil
    GuiComponent = require("scripts.runtime.lib.gui-component")
  end)

  describe("define", function ()
    it("creates a new GuiComponent class", function ()
      local TestComponent = GuiComponent.define("TestComponent")

      assert.is_not_nil(TestComponent)
      assert.are_equal("TestComponent", TestComponent.component_name)
      assert.are_equal("mks-qptc-handler:TestComponent:", TestComponent.handler_tag_prefix)
    end)

    it("registers metatable for serialization", function ()
      local s = spy.on(_G.script, "register_metatable")

      local TestComponent = GuiComponent.define("TestComponent")

      assert.spy(s).called(1)
      assert.spy(s).called_with("mks-qptc-TestComponent", TestComponent)
    end)

    it("creates different classes for different names", function ()
      local ComponentA = GuiComponent.define("ComponentA")
      local ComponentB = GuiComponent.define("ComponentB")

      assert.are_not_equal(ComponentA, ComponentB)
      assert.are_equal("ComponentA", ComponentA.component_name)
      assert.are_equal("ComponentB", ComponentB.component_name)
      assert.are_equal("mks-qptc-handler:ComponentA:", ComponentA.handler_tag_prefix)
      assert.are_equal("mks-qptc-handler:ComponentB:", ComponentB.handler_tag_prefix)
    end)
  end)

  describe("instance creation and inheritance", function ()
    local TestComponent

    before_each(function ()
      TestComponent = GuiComponent.define("TestComponent")
    end)

    it("creates instances with component methods", function ()
      local instance = setmetatable({}, TestComponent)

      assert.is_not_nil(instance)
      assert.are_equal(TestComponent, getmetatable(instance))
      assert.is_function(instance.listen_to_events)
    end)

    it("inherits component properties", function ()
      local instance = setmetatable({}, TestComponent)

      assert.are_equal("TestComponent", instance.component_name)
      assert.are_equal("mks-qptc-handler:TestComponent:", instance.handler_tag_prefix)
    end)

    it("allows adding custom methods to class", function ()
      TestComponent.custom_method = spy.new(function (self, value) return "test" .. value end)

      local instance = setmetatable({}, TestComponent)

      assert.are_equal("testhello", instance:custom_method("hello"))
      assert.spy(TestComponent.custom_method).called(1)
      assert.spy(TestComponent.custom_method).called_with(instance, "hello")
    end)
  end)

  describe("listen_to_events", function ()
    local TestComponent
    local instance

    before_each(function ()
      TestComponent = GuiComponent.define("TestComponent")
      instance = setmetatable({}, TestComponent)
    end)

    it("registers event handlers", function ()
      TestComponent.test_handler = spy.new(function () end)

      instance:listen_to_events({
        [defines.events.on_player_created] = TestComponent.test_handler,
      })

      local event_data = { name = defines.events.on_player_created }
      Event.dispatch_event(event_data --[[@as EventData]])

      assert.spy(TestComponent.test_handler).called_with(instance, event_data)
    end)

    it("registers multiple event handlers", function ()
      TestComponent.created_handler = spy.new(function () end)
      TestComponent.removed_handler = spy.new(function () end)

      instance:listen_to_events({
        [defines.events.on_player_created] = TestComponent.created_handler,
        [defines.events.on_player_removed] = TestComponent.removed_handler,
      })

      Event.dispatch_event({ name = defines.events.on_player_created })
      Event.dispatch_event({ name = defines.events.on_player_removed })

      assert.spy(TestComponent.created_handler).called(1)
      assert.spy(TestComponent.removed_handler).called(1)
    end)

    it("overwrites existing event handlers", function ()
      TestComponent.handler1 = spy.new(function () end)
      TestComponent.handler2 = spy.new(function () end)

      instance:listen_to_events({
        [defines.events.on_player_created] = TestComponent.handler1,
      })

      instance:listen_to_events({
        [defines.events.on_player_created] = TestComponent.handler2,
      })

      Event.dispatch_event({ name = defines.events.on_player_created })

      assert.spy(TestComponent.handler1).called(0)
      assert.spy(TestComponent.handler2).called(1)
    end)

    it("throws error for non-existent method", function ()
      local non_existent_method = function () end

      assert.has_error(function ()
        instance:listen_to_events({
          [defines.events.on_gui_click] = non_existent_method,
        })
      end, "Method not found for handler")
    end)
  end)

  describe("listen_to_gui_events", function ()
    local TestComponent
    local instance
    local mock_element

    before_each(function ()
      TestComponent = GuiComponent.define("TestComponent")
      instance = setmetatable({}, TestComponent)
      mock_element = {
        tags = {},
      }
    end)

    it("sets up GUI event handlers", function ()
      --- @type luassert.spy
      TestComponent.click_handler = spy.new(function () end)

      instance:listen_to_gui_events(mock_element, {
        [defines.events.on_gui_click] = TestComponent.click_handler,
      })

      -- Check that tags were set
      assert.are_equal("click_handler", mock_element.tags["mks-qptc-handler:TestComponent:1"])

      local test_event = ({
        name = defines.events.on_gui_click,
        element = mock_element,
      }) --[[@as EventData.on_gui_click]]
      Event.dispatch_event(test_event)

      assert.spy(TestComponent.click_handler).called(1)
      assert.spy(TestComponent.click_handler).called_with(instance, test_event)
    end)

    it("sets up multiple GUI event handlers", function ()
      --- @type luassert.spy
      TestComponent.handler1 = spy.new(function () end)
      --- @type luassert.spy
      TestComponent.handler2 = spy.new(function () end)

      instance:listen_to_gui_events(mock_element, {
        [defines.events.on_gui_click] = TestComponent.handler1,
        [defines.events.on_gui_opened] = TestComponent.handler2,
      })

      -- Check that tags were set
      assert.are_equal("handler1", mock_element.tags["mks-qptc-handler:TestComponent:1"])
      assert.are_equal("handler2", mock_element.tags["mks-qptc-handler:TestComponent:3"])

      Event.dispatch_event({ name = defines.events.on_gui_click, element = mock_element })
      assert.spy(TestComponent.handler1).called(1)
      assert.spy(TestComponent.handler2).called(0)

      Event.dispatch_event({ name = defines.events.on_gui_opened, element = mock_element })
      assert.spy(TestComponent.handler1).called(1)
      assert.spy(TestComponent.handler2).called(1)
    end)

    it("preserves existing tags", function ()
      mock_element.tags = {
        existing_tag = "existing_value",
      }

      TestComponent.click_handler = spy.new(function () end)

      instance:listen_to_gui_events(mock_element, {
        [defines.events.on_gui_click] = TestComponent.click_handler,
      })

      assert.are_equal("existing_value", mock_element.tags.existing_tag)
      assert.are_equal("click_handler", mock_element.tags["mks-qptc-handler:TestComponent:1"])
    end)

    it("throws error for non-existent method", function ()
      local non_existent_method = function () end

      assert.has_error(function ()
        instance:listen_to_gui_events(mock_element, {
          [defines.events.on_gui_click] = non_existent_method,
        })
      end, "Method not found for handler")
    end)
  end)

  describe("rebind_event_listeners", function ()
    local TestComponent
    local instance

    before_each(function ()
      TestComponent = GuiComponent.define("TestComponent")
      instance = setmetatable({}, TestComponent)
    end)

    it("does nothing when no event handlers", function ()
      assert.no_error(function ()
        instance:rebind_event_listeners()
      end)
    end)

    it("rebinds existing event handlers", function ()
      TestComponent.test_handler = spy.new(function () end)

      instance:listen_to_events({
        [defines.events.on_player_created] = TestComponent.test_handler,
      })

      Event.clear_event_listeners()

      local test_event = ({ name = defines.events.on_player_created }) --[[@as EventData]]

      -- Checks listener is removed
      Event.dispatch_event(test_event)
      assert.spy(TestComponent.test_handler).called(0)

      instance:rebind_event_listeners()

      Event.dispatch_event(test_event)
      assert.spy(TestComponent.test_handler).called(1)
      assert.spy(TestComponent.test_handler).called_with(instance, test_event)
    end)
  end)

  describe("clear_event_listeners", function ()
    local TestComponent
    local instance

    before_each(function ()
      TestComponent = GuiComponent.define("TestComponent")
      instance = setmetatable({}, TestComponent)
    end)

    it("does nothing when no event handlers", function ()
      assert.no_error(function ()
        instance:clear_event_listeners()
      end)
    end)

    it("clears existing event handlers", function ()
      TestComponent.test_handler = spy.new(function () end)

      instance:listen_to_events({
        [defines.events.on_player_created] = TestComponent.test_handler,
      })

      instance:clear_event_listeners()

      Event.dispatch_event({ name = defines.events.on_player_created })
      assert.spy(TestComponent.test_handler).called(0)
    end)
  end)

  describe("load", function ()
    local TestComponent
    local instance

    before_each(function ()
      TestComponent = GuiComponent.define("TestComponent")
      instance = setmetatable({}, TestComponent)
    end)

    it("rebinds event listeners", function ()
      local s = spy.on(instance, "rebind_event_listeners")

      instance:load()

      assert.spy(s).called_with(instance)
    end)
  end)

  describe("destroy", function ()
    local TestComponent
    local instance

    before_each(function ()
      TestComponent = GuiComponent.define("TestComponent")
      instance = setmetatable({}, TestComponent)
    end)

    it("clears event listeners", function ()
      local s = spy.on(instance, "clear_event_listeners")

      instance:destroy()

      assert.spy(s).called_with(instance)
    end)
  end)

  describe("integration", function ()
    it("handles multiple instances independently", function ()
      local TestComponent = GuiComponent.define("TestComponent")
      local instance1 = setmetatable({}, TestComponent)
      local instance2 = setmetatable({}, TestComponent)

      TestComponent.test_handler = spy.new(function () end)

      instance1:listen_to_events({
        [defines.events.on_player_created] = TestComponent.test_handler,
      })
      instance2:listen_to_events({
        [defines.events.on_player_created] = TestComponent.test_handler,
      })

      local test_event = ({ name = defines.events.on_player_created }) --[[@as EventData]]
      Event.dispatch_event(test_event)
      assert.spy(TestComponent.test_handler).called(2)
      assert.spy(TestComponent.test_handler).called_with(instance1, test_event)
      assert.spy(TestComponent.test_handler).called_with(instance2, test_event)
    end)
  end)
end)
