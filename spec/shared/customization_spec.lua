local cjson = require("cjson")
local Customization = require("scripts.shared.customization")
local helper = require("spec.helper")

describe("Customization", function ()
  setup(function ()
    helper.reset_mocks()
  end)

  describe("to_json", function ()
    it("converts customization to json", function ()
      local customization = {
        shortcuts = { "shortcut1", "shortcut2" },
        hidden_shortcuts = { "hidden1" },
      }

      local json = Customization.to_json(customization)
      assert.is_string(json)
      assert.are_not_equal("", json)

      local decoded = cjson.decode(json)
      assert.is_table(decoded)
      --- @cast decoded table
      assert.are_same({ "shortcut1", "shortcut2" }, decoded.s)
      assert.are_same({ "hidden1" }, decoded.h)
    end)

    it("handles empty customization", function ()
      local customization = {
        shortcuts = {},
        hidden_shortcuts = {},
      }

      local json = Customization.to_json(customization)
      local decoded = cjson.decode(json)

      assert.is_table(decoded)
      --- @cast decoded table
      assert.are_same({}, decoded.s)
      assert.are_same({}, decoded.h)
    end)

    it("handles customization with only shortcuts", function ()
      local customization = {
        shortcuts = { "shortcut1", "shortcut2", "shortcut3" },
        hidden_shortcuts = {},
      }

      local json = Customization.to_json(customization)
      local decoded = cjson.decode(json)

      assert.is_table(decoded)
      --- @cast decoded table
      assert.are_same({ "shortcut1", "shortcut2", "shortcut3" }, decoded.s)
      assert.are_same({}, decoded.h)
    end)

    it("handles customization with only hidden shortcuts", function ()
      local customization = {
        shortcuts = {},
        hidden_shortcuts = { "hidden1", "hidden2" },
      }

      local json = Customization.to_json(customization)
      local decoded = cjson.decode(json)

      assert.is_table(decoded)
      --- @cast decoded table
      assert.are_same({}, decoded.s)
      assert.are_same({ "hidden1", "hidden2" }, decoded.h)
    end)
  end)

  describe("from_json", function ()
    it("parses valid json", function ()
      local json_string = '{"s": ["shortcut1", "shortcut2"], "h": ["hidden1"]}'

      local customization = Customization.from_json(json_string)

      assert.is_table(customization)
      --- @cast customization Customization
      assert.are_same({ "shortcut1", "shortcut2" }, customization.shortcuts)
      assert.are_same({ "hidden1" }, customization.hidden_shortcuts)
    end)

    it("returns nil for invalid json", function ()
      local invalid_json = '{"invalid json"}'

      local customization = Customization.from_json(invalid_json)

      assert.is_nil(customization)
    end)

    it("returns nil for empty string", function ()
      local customization = Customization.from_json("")

      assert.is_nil(customization)
    end)

    it("returns nil for null string", function ()
      local customization = Customization.from_json("null")

      assert.is_nil(customization)
    end)

    it("returns nil for non-table parsed data", function ()
      local customization = Customization.from_json('"string"')

      assert.is_nil(customization)
    end)

    it("returns nil when s field is missing", function ()
      local json_string = '{"h": ["hidden1"]}'

      local customization = Customization.from_json(json_string)

      assert.is_nil(customization)
    end)

    it("returns nil when h field is missing", function ()
      local json_string = '{"s": ["shortcut1"]}'

      local customization = Customization.from_json(json_string)

      assert.is_nil(customization)
    end)

    it("returns nil when s field is not table", function ()
      local json_string = '{"s": "not-table", "h": {}}'

      local customization = Customization.from_json(json_string)

      assert.is_nil(customization)
    end)

    it("returns nil when h field is not table", function ()
      local json_string = '{"s": {}, "h": "not-table"}'

      local customization = Customization.from_json(json_string)

      assert.is_nil(customization)
    end)

    it("handles empty arrays", function ()
      local json_string = '{"s": {}, "h": {}}'

      local customization = Customization.from_json(json_string)

      assert.is_not_nil(customization)
      --- @cast customization Customization
      assert.are_same({}, customization.shortcuts)
      assert.are_same({}, customization.hidden_shortcuts)
    end)

    it("handles additional fields gracefully", function ()
      local json_string = '{"s": ["shortcut1"], "h": ["hidden1"], "extra": "value"}'

      local customization = Customization.from_json(json_string)

      assert.is_not_nil(customization)
      --- @cast customization Customization
      assert.are_same({ "shortcut1" }, customization.shortcuts)
      assert.are_same({ "hidden1" }, customization.hidden_shortcuts)
    end)
  end)

  describe("from_settings", function ()
    it("returns empty customization when setting is nil", function ()
      settings.startup["mks-qptc-customize-json"] = nil

      local customization = Customization.from_settings()

      assert.are_same({}, customization.shortcuts)
      assert.are_same({}, customization.hidden_shortcuts)
    end)

    it("returns empty customization when setting value is empty string", function ()
      settings.startup["mks-qptc-customize-json"] = {
        value = "",
      }

      local customization = Customization.from_settings()

      assert.are_same({}, customization.shortcuts)
      assert.are_same({}, customization.hidden_shortcuts)
    end)

    it("returns customization from valid setting", function ()
      settings.startup["mks-qptc-customize-json"] = {
        value = '{"s": ["shortcut1"], "h": ["hidden1"]}',
      }

      local customization = Customization.from_settings()

      assert.are_same({ "shortcut1" }, customization.shortcuts)
      assert.are_same({ "hidden1" }, customization.hidden_shortcuts)
    end)

    it("returns empty customization when setting value is invalid json", function ()
      settings.startup["mks-qptc-customize-json"] = {
        value = '{"invalid json"',
      }

      local customization = Customization.from_settings()

      assert.are_same({}, customization.shortcuts)
      assert.are_same({}, customization.hidden_shortcuts)
    end)
  end)

  describe("empty", function ()
    it("returns empty customization", function ()
      local customization = Customization.empty()

      assert.are_same({}, customization.shortcuts)
      assert.are_same({}, customization.hidden_shortcuts)
    end)

    it("returns new instance each time", function ()
      local customization1 = Customization.empty()
      local customization2 = Customization.empty()

      assert.are_not_equal(customization1, customization2)
    end)
  end)

  describe("roundtrip", function ()
    it("can serialize and deserialize correctly", function ()
      local original = {
        shortcuts = { "shortcut1", "shortcut2", "shortcut3" },
        hidden_shortcuts = { "hidden1", "hidden2" },
      }

      local json = Customization.to_json(original)
      local restored = Customization.from_json(json)

      assert.is_not_nil(restored)
      --- @cast restored Customization
      assert.are_same(original.shortcuts, restored.shortcuts)
      assert.are_same(original.hidden_shortcuts, restored.hidden_shortcuts)
    end)

    it("handles empty customization roundtrip", function ()
      local original = Customization.empty()

      local json = Customization.to_json(original)
      local restored = Customization.from_json(json)

      assert.is_not_nil(restored)
      --- @cast restored Customization
      assert.are_same(original.shortcuts, restored.shortcuts)
      assert.are_same(original.hidden_shortcuts, restored.hidden_shortcuts)
    end)

    it("handles complex shortcut names", function ()
      local original = {
        shortcuts = { "shortcut-with-dash", "shortcut_with_underscore", "shortcut123" },
        hidden_shortcuts = { "hidden-with.special*chars" },
      }

      local json = Customization.to_json(original)
      local restored = Customization.from_json(json)

      assert.is_not_nil(restored)
      --- @cast restored Customization
      assert.are_same(original.shortcuts, restored.shortcuts)
      assert.are_same(original.hidden_shortcuts, restored.hidden_shortcuts)
    end)
  end)
end)
