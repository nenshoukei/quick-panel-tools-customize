--- @diagnostic disable: missing-fields
local ShortcutSlots = require("scripts.runtime.lib.shortcut-slots")
local helper = require("spec.helper")

describe("ShortcutSlots", function ()
  setup(function ()
    helper.reset_mocks()
  end)

  describe("new", function ()
    it("creates empty ShortcutSlots", function ()
      local slots = ShortcutSlots.new()

      assert.is_not_nil(slots)
      assert.is_true(next(slots.name_to_position) == nil)
      assert.is_true(next(slots.position_to_name) == nil)
    end)
  end)

  describe("new_with_customization", function ()
    local dict = {
      ["shortcut-a"] = {},
      ["shortcut-b"] = {},
      ["shortcut-c"] = {},
      ["shortcut-d"] = {},
    }

    it("creates ShortcutSlots with visible shortcuts", function ()
      --- @type Customization
      local customization = {
        shortcuts = { "shortcut-a", "shortcut-b" },
        hidden_shortcuts = {},
      }

      local slots = ShortcutSlots.new_with_customization(customization, dict)

      assert.are_equal("v0000000001", slots:get_position_of("shortcut-a"))
      assert.are_equal("v0000000002", slots:get_position_of("shortcut-b"))
      assert.are_equal("shortcut-a", slots:get_name_at("v0000000001"))
      assert.are_equal("shortcut-b", slots:get_name_at("v0000000002"))
    end)

    it("creates ShortcutSlots with hidden shortcuts", function ()
      --- @type Customization
      local customization = {
        shortcuts = {},
        hidden_shortcuts = { "shortcut-a", "shortcut-b" },
      }

      local slots = ShortcutSlots.new_with_customization(customization, dict)

      assert.are_equal("h0000000001", slots:get_position_of("shortcut-a"))
      assert.are_equal("h0000000002", slots:get_position_of("shortcut-b"))
      assert.are_equal("shortcut-a", slots:get_name_at("h0000000001"))
      assert.are_equal("shortcut-b", slots:get_name_at("h0000000002"))
    end)

    it("adds new shortcuts at the end of visible shortcuts", function ()
      --- @type Customization
      local customization = {
        shortcuts = { "shortcut-a" },
        hidden_shortcuts = {},
      }
      --- @type ShortcutDict
      local new_shortcuts_dict = {
        ["shortcut-a"] = {},
        ["shortcut-b"] = {},
      }

      local slots = ShortcutSlots.new_with_customization(customization, new_shortcuts_dict)

      assert.are_equal("v0000000001", slots:get_position_of("shortcut-a"))
      assert.are_equal("v0000000002", slots:get_position_of("shortcut-b"))
      assert.are_equal("shortcut-a", slots:get_name_at("v0000000001"))
      assert.are_equal("shortcut-b", slots:get_name_at("v0000000002"))
    end)

    it("skips empty strings as placeholders", function ()
      local customization = {
        shortcuts = { "shortcut-a", "", "shortcut-b" },
        hidden_shortcuts = { "", "shortcut-c" },
      }

      local slots = ShortcutSlots.new_with_customization(customization, dict)

      assert.are_equal("v0000000001", slots:get_position_of("shortcut-a"))
      assert.are_equal("v0000000003", slots:get_position_of("shortcut-b"))
      assert.are_equal("h0000000002", slots:get_position_of("shortcut-c"))

      assert.are_equal("shortcut-a", slots:get_name_at("v0000000001"))
      assert.is_nil(slots:get_name_at("v0000000002"))
      assert.are_equal("shortcut-b", slots:get_name_at("v0000000003"))
      assert.is_nil(slots:get_name_at("h0000000001"))
      assert.are_equal("shortcut-c", slots:get_name_at("h0000000002"))
    end)

    it("replaces non-existent shortcuts with placeholders", function ()
      local customization = {
        shortcuts = { "shortcut-a", "non-existent", "shortcut-b" },
        hidden_shortcuts = { "shortcut-c", "another-non-existent", "shortcut-d" },
      }

      local slots = ShortcutSlots.new_with_customization(customization, dict)

      assert.are_equal("v0000000001", slots:get_position_of("shortcut-a"))
      assert.are_equal("v0000000003", slots:get_position_of("shortcut-b"))
      assert.are_equal("h0000000001", slots:get_position_of("shortcut-c"))
      assert.are_equal("h0000000003", slots:get_position_of("shortcut-d"))

      assert.are_equal("shortcut-a", slots:get_name_at("v0000000001"))
      assert.is_nil(slots:get_name_at("v0000000002"))
      assert.are_equal("shortcut-b", slots:get_name_at("v0000000003"))
      assert.are_equal("shortcut-c", slots:get_name_at("h0000000001"))
      assert.is_nil(slots:get_name_at("h0000000002"))
      assert.are_equal("shortcut-d", slots:get_name_at("h0000000003"))
    end)
  end)

  describe("position methods", function ()
    local slots

    before_each(function ()
      slots = ShortcutSlots.new()
      slots.name_to_position["test-shortcut"] = "v0000000005"
      slots.position_to_name["v0000000005"] = "test-shortcut"
    end)

    it("gets name at position", function ()
      assert.are_equal("test-shortcut", slots:get_name_at("v0000000005"))
      assert.is_nil(slots:get_name_at("v0000000001"))
    end)

    it("gets position of name", function ()
      assert.are_equal("v0000000005", slots:get_position_of("test-shortcut"))
      assert.is_nil(slots:get_position_of("non-existent"))
    end)

    it("identifies visible positions", function ()
      assert.is_true(slots:is_visible_position("v0000000005"))
      assert.is_false(slots:is_visible_position("h0000000001"))
    end)

    it("identifies hidden positions", function ()
      assert.is_false(slots:is_hidden_position("v0000000005"))
      assert.is_true(slots:is_hidden_position("h0000000001"))
    end)
  end)

  describe("swap", function ()
    local slots

    before_each(function ()
      slots = ShortcutSlots.new()
      slots.name_to_position["shortcut-a"] = "v0000000001"
      slots.position_to_name["v0000000001"] = "shortcut-a"
      slots.name_to_position["shortcut-b"] = "v0000000002"
      slots.position_to_name["v0000000002"] = "shortcut-b"
    end)

    it("swaps two occupied positions", function ()
      slots:swap("v0000000001", "v0000000002")

      assert.are_equal("v0000000002", slots:get_position_of("shortcut-a"))
      assert.are_equal("v0000000001", slots:get_position_of("shortcut-b"))
      assert.are_equal("shortcut-b", slots:get_name_at("v0000000001"))
      assert.are_equal("shortcut-a", slots:get_name_at("v0000000002"))
    end)

    it("swaps occupied with empty position", function ()
      slots:swap("v0000000001", "v0000000003")

      assert.are_equal("v0000000003", slots:get_position_of("shortcut-a"))
      assert.are_equal("v0000000002", slots:get_position_of("shortcut-b"))
      assert.is_nil(slots:get_name_at("v0000000001"))
      assert.are_equal("shortcut-a", slots:get_name_at("v0000000003"))
    end)

    it("does nothing when positions are the same", function ()
      slots:swap("v0000000001", "v0000000001")

      assert.are_equal("v0000000001", slots:get_position_of("shortcut-a"))
      assert.are_equal("shortcut-a", slots:get_name_at("v0000000001"))
    end)

    it("does nothing when both positions are empty", function ()
      slots:swap("v0000000003", "v0000000004")

      assert.is_nil(slots:get_name_at("v0000000003"))
      assert.is_nil(slots:get_name_at("v0000000004"))
    end)
  end)

  describe("toggle_visibility", function ()
    local slots

    before_each(function ()
      slots = ShortcutSlots.new()
      slots.name_to_position["shortcut-a"] = "v0000000001"
      slots.position_to_name["v0000000001"] = "shortcut-a"
      slots.name_to_position["shortcut-b"] = "h0000000001"
      slots.position_to_name["h0000000001"] = "shortcut-b"
      slots.name_to_position["shortcut-c"] = "h0000000003"
      slots.position_to_name["h0000000003"] = "shortcut-c"
    end)

    it("toggles visible to hidden", function ()
      local new_position = slots:toggle_visibility("v0000000001")

      assert.are_equal("h0000000002", new_position)
      assert.are_equal("h0000000002", slots:get_position_of("shortcut-a"))
      assert.are_equal("shortcut-a", slots:get_name_at("h0000000002"))
      assert.is_nil(slots:get_name_at("v0000000001"))
    end)

    it("toggles hidden to visible", function ()
      local new_position = slots:toggle_visibility("h0000000001")

      assert.are_equal("v0000000002", new_position)
      assert.are_equal("v0000000002", slots:get_position_of("shortcut-b"))
      assert.are_equal("shortcut-b", slots:get_name_at("v0000000002"))
      assert.is_nil(slots:get_name_at("h0000000001"))
    end)

    it("returns nil for empty position", function ()
      local result = slots:toggle_visibility("v0000000002")

      assert.is_nil(result)
    end)
  end)

  describe("iter_visible_pages", function ()
    --- @type ShortcutSlots
    local slots

    before_each(function ()
      slots = ShortcutSlots.new()
      -- Add shortcuts at positions 1, 2, 5, 9
      slots.name_to_position["shortcut-a"] = "v0000000001"
      slots.position_to_name["v0000000001"] = "shortcut-a"
      slots.name_to_position["shortcut-b"] = "v0000000002"
      slots.position_to_name["v0000000002"] = "shortcut-b"
      slots.name_to_position["shortcut-c"] = "v0000000005"
      slots.position_to_name["v0000000005"] = "shortcut-c"
      slots.name_to_position["shortcut-d"] = "v0000000009"
      slots.position_to_name["v0000000009"] = "shortcut-d"
    end)

    it("iterates through visible pages", function ()
      local pages = {}
      for page in slots:iter_visible_pages() do
        pages[#pages + 1] = page
      end

      -- should have at least 5 pages
      assert.are_equal(5, #pages)

      assert.are_equal(1, pages[1].index)
      assert.are_equal(2, pages[2].index)
      assert.are_equal(3, pages[3].index)
    end)

    it("iterates through visible slots", function ()
      local iter = slots:iter_visible_pages()
      local page1 = iter()
      local page2 = iter()
      assert.is_not_nil(page1)
      assert.is_not_nil(page2)
      --- @cast page1 ShortcutSlots.VisiblePageInfo
      --- @cast page2 ShortcutSlots.VisiblePageInfo

      local page1_slots = {}
      for slot in page1.iter_slots() do
        page1_slots[#page1_slots + 1] = slot
      end

      local page2_slots = {}
      for slot in page2.iter_slots() do
        page2_slots[#page2_slots + 1] = slot
      end

      -- should have 8 slots per page
      assert.are_equal(8, #page1_slots)

      assert.are_equal(1, page1_slots[1].index)
      assert.are_equal(1, page1_slots[1].index_in_page)
      assert.are_equal("shortcut-a", page1_slots[1].name)
      assert.are_equal("v0000000001", page1_slots[1].position)

      assert.are_equal(2, page1_slots[2].index)
      assert.are_equal(2, page1_slots[2].index_in_page)
      assert.are_equal("shortcut-b", page1_slots[2].name)
      assert.are_equal("v0000000002", page1_slots[2].position)

      assert.are_equal(3, page1_slots[3].index)
      assert.are_equal(3, page1_slots[3].index_in_page)
      assert.is_nil(page1_slots[3].name)
      assert.are_equal("v0000000003", page1_slots[3].position)

      assert.is_nil(page1_slots[4].name)
      assert.are_equal("shortcut-c", page1_slots[5].name)
      assert.is_nil(page1_slots[6].name)
      assert.is_nil(page1_slots[7].name)
      assert.is_nil(page1_slots[8].name)

      assert.are_equal(8, #page2_slots)

      assert.are_equal(9, page2_slots[1].index)
      assert.are_equal(1, page2_slots[1].index_in_page)
      assert.are_equal("shortcut-d", page2_slots[1].name)
      assert.are_equal("v0000000009", page2_slots[1].position)

      assert.are_equal(10, page2_slots[2].index)
      assert.are_equal(2, page2_slots[2].index_in_page)
      assert.is_nil(page2_slots[2].name)
      assert.are_equal("v0000000010", page2_slots[2].position)
    end)

    it("expands visible slots", function ()
      local expanded_slots = ShortcutSlots.new()
      expanded_slots.name_to_position["shortcut-a"] = "v0000000050"
      expanded_slots.position_to_name["v0000000050"] = "shortcut-a"

      local pages = {}
      for page in expanded_slots:iter_visible_pages() do
        pages[#pages + 1] = page
      end

      assert.are_equal(7, #pages)

      local page7_slots = {}
      for slot in pages[7]:iter_slots() do
        page7_slots[#page7_slots + 1] = slot
      end

      assert.are_equal(8, #page7_slots)
      assert.is_nil(page7_slots[1].name)
      assert.are_equal("v0000000049", page7_slots[1].position)
      assert.are_equal("shortcut-a", page7_slots[2].name)
      assert.are_equal("v0000000050", page7_slots[2].position)
    end)
  end)

  describe("iter_hidden_slots", function ()
    local slots

    before_each(function ()
      slots = ShortcutSlots.new()
      slots.name_to_position["shortcut-a"] = "h0000000001"
      slots.position_to_name["h0000000001"] = "shortcut-a"
      slots.name_to_position["shortcut-b"] = "h0000000005"
      slots.position_to_name["h0000000005"] = "shortcut-b"
      slots.name_to_position["shortcut-c"] = "h0000000012"
      slots.position_to_name["h0000000012"] = "shortcut-c"
    end)

    it("iterates through hidden slots", function ()
      local hidden_slots = {}
      local iter_slots = slots:iter_hidden_slots()
      for slot in iter_slots do
        hidden_slots[#hidden_slots + 1] = slot
      end

      -- Should have 20 slots (2 rows of 10)
      assert.are_equal(20, #hidden_slots)

      -- Check specific slots
      assert.are_equal(1, hidden_slots[1].index)
      assert.are_equal("shortcut-a", hidden_slots[1].name)
      assert.are_equal("h0000000001", hidden_slots[1].position)

      assert.are_equal(2, hidden_slots[2].index)
      assert.is_nil(hidden_slots[2].name)
      assert.are_equal("h0000000002", hidden_slots[2].position)

      assert.are_equal(5, hidden_slots[5].index)
      assert.are_equal("shortcut-b", hidden_slots[5].name)
      assert.are_equal("h0000000005", hidden_slots[5].position)

      assert.are_equal(6, hidden_slots[6].index)
      assert.is_nil(hidden_slots[6].name)
      assert.are_equal("h0000000006", hidden_slots[6].position)

      assert.are_equal(12, hidden_slots[12].index)
      assert.are_equal("shortcut-c", hidden_slots[12].name)
      assert.are_equal("h0000000012", hidden_slots[12].position)

      assert.are_equal(20, hidden_slots[20].index)
      assert.is_nil(hidden_slots[20].name)
      assert.are_equal("h0000000020", hidden_slots[20].position)
    end)
  end)

  describe("get_customization", function ()
    local slots

    before_each(function ()
      slots = ShortcutSlots.new()
      -- Set up some slots
      slots.name_to_position["shortcut-a"] = "v0000000002"
      slots.position_to_name["v0000000002"] = "shortcut-a"
      slots.name_to_position["shortcut-b"] = "v0000000005"
      slots.position_to_name["v0000000005"] = "shortcut-b"
      slots.name_to_position["shortcut-c"] = "h0000000002"
      slots.position_to_name["h0000000002"] = "shortcut-c"
      slots.name_to_position["shortcut-d"] = "h0000000005"
      slots.position_to_name["h0000000005"] = "shortcut-d"
    end)

    it("converts slots back to customization", function ()
      local customization = slots:get_customization()

      -- Visible shortcuts keep placeholders
      assert.are_same(
        { "", "shortcut-a", "", "", "shortcut-b" },
        customization.shortcuts
      )
      -- Hidden shortcuts do not keep placeholders
      assert.are_same(
        { "shortcut-c", "shortcut-d" },
        customization.hidden_shortcuts
      )
    end)

    it("handles empty slots correctly", function ()
      local empty_slots = ShortcutSlots.new()
      local customization = empty_slots:get_customization()

      assert.are_equal(0, #customization.shortcuts)
      assert.are_equal(0, #customization.hidden_shortcuts)
    end)
  end)
end)
