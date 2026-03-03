--- @diagnostic disable: missing-fields
local ShortcutDict = require("scripts.runtime.lib.shortcut-dict")
local helper = require("spec.helper")

describe("ShortcutDict", function ()
  setup(function ()
    helper.reset_mocks()
  end)

  before_each(function ()
    -- Clear module cache to reset static variables
    package.loaded["scripts.runtime.lib.shortcut-dict"] = nil
    ShortcutDict = require("scripts.runtime.lib.shortcut-dict")
  end)

  describe("get_all", function ()
    it("returns empty dict when no shortcuts exist", function ()
      _G.prototypes.mod_data["mks-qptc-shortcut-list"] = {
        data = { shortcut_list = {} },
      }

      local result = ShortcutDict.get_all()
      assert.is_true(next(result) == nil)
    end)

    it("creates entries for valid shortcuts", function ()
      _G.prototypes.mod_data["mks-qptc-shortcut-list"] = {
        data = {
          shortcut_list = {
            { name = "test-shortcut-a", toggleable = true },
            { name = "give-blueprint",  style = "blue" },
          },
        },
      }
      _G.prototypes.item["mks-qptc-shortcut-test-shortcut-a"] = {
        localised_name = { "shortcut-name.test-shortcut-a" },
        order = "a",
      }
      _G.prototypes.item["mks-qptc-shortcut-give-blueprint"] = {
        localised_name = { "shortcut-name.give-blueprint" },
        order = "b",
      }

      local result = ShortcutDict.get_all()
      local entry_a = result["test-shortcut-a"]
      local entry_b = result["give-blueprint"]

      assert.is_not_nil(entry_a)
      assert.are_equal("test-shortcut-a", entry_a.name)
      assert.are_same({ "shortcut-name.test-shortcut-a" }, entry_a.localised_name)
      assert.are_equal("item/mks-qptc-shortcut-test-shortcut-a", entry_a.icon)
      assert.are_equal("default", entry_a.style)
      assert.are_equal("mks-qptc-shortcut-test-shortcut-a", entry_a.item_name)
      assert.is_true(entry_a.toggleable)
      assert.are_equal("a", entry_a.order)
      assert.is_true(entry_a.is_modded)

      assert.is_not_nil(entry_b)
      assert.are_equal("give-blueprint", entry_b.name)
      assert.are_same({ "shortcut-name.give-blueprint" }, entry_b.localised_name)
      assert.are_equal("item/mks-qptc-shortcut-give-blueprint", entry_b.icon)
      assert.are_equal("blue", entry_b.style)
      assert.are_equal("mks-qptc-shortcut-give-blueprint", entry_b.item_name)
      assert.is_false(entry_b.toggleable)
      assert.are_equal("b", entry_b.order)
      assert.is_false(entry_b.is_modded)
    end)

    it("identifies base shortcuts correctly", function ()
      _G.prototypes.mod_data["mks-qptc-shortcut-list"] = {
        data = {
          shortcut_list = {
            { name = "toggle-alt-mode" },
            { name = "custom-mod-shortcut" },
          },
        },
      }
      _G.prototypes.item["mks-qptc-shortcut-toggle-alt-mode"] = {
        localised_name = { "item-name.toggle-alt-mode" },
      }
      _G.prototypes.item["mks-qptc-shortcut-custom-mod-shortcut"] = {
        localised_name = { "item-name.custom-mod-shortcut" },
      }

      local result = ShortcutDict.get_all()

      assert.is_false(result["toggle-alt-mode"].is_modded)
      assert.is_true(result["custom-mod-shortcut"].is_modded)
    end)

    it("skips shortcuts without corresponding items", function ()
      _G.prototypes.mod_data["mks-qptc-shortcut-list"] = {
        data = {
          shortcut_list = {
            { name = "valid-shortcut" },
            { name = "missing-shortcut" },
          },
        },
      }
      _G.prototypes.item["mks-qptc-shortcut-valid-shortcut"] = {
        localised_name = { "item-name.valid-shortcut" },
      }
      -- Note: missing item for "missing-shortcut"

      local result = ShortcutDict.get_all()

      assert.is_not_nil(result["valid-shortcut"])
      assert.is_nil(result["missing-shortcut"])
    end)

    it("caches results", function ()
      _G.prototypes.mod_data["mks-qptc-shortcut-list"] = {
        data = {
          shortcut_list = {
            { name = "test-shortcut" },
          },
        },
      }
      _G.prototypes.item["mks-qptc-shortcut-test-shortcut"] = {
        localised_name = { "item-name.test-shortcut" },
      }

      local result1 = ShortcutDict.get_all()
      local result2 = ShortcutDict.get_all()

      assert.are_equal(result1, result2)
    end)

    it("throws error when mod-data is missing", function ()
      _G.prototypes.mod_data["mks-qptc-shortcut-list"] = nil

      assert.has_error(function ()
        ShortcutDict.get_all()
      end, "mod-data not found")
    end)

    it("throws error when mod-data.data is missing", function ()
      _G.prototypes.mod_data["mks-qptc-shortcut-list"] = {}

      assert.has_error(function ()
        ShortcutDict.get_all()
      end, "mod-data not found")
    end)
  end)

  describe("get", function ()
    before_each(function ()
      _G.prototypes.mod_data["mks-qptc-shortcut-list"] = {
        data = {
          shortcut_list = {
            { name = "test-shortcut" },
          },
        },
      }
      _G.prototypes.item["mks-qptc-shortcut-test-shortcut"] = {
        localised_name = { "item-name.test-shortcut" },
      }
    end)

    it("returns entry for existing shortcut", function ()
      local entry = ShortcutDict.get("test-shortcut")

      assert.is_not_nil(entry)
      --- @cast entry ShortcutDictEntry
      assert.are_equal("test-shortcut", entry.name)
    end)

    it("returns nil for non-existing shortcut", function ()
      local entry = ShortcutDict.get("non-existing")

      assert.is_nil(entry)
    end)
  end)
end)
