local consts = require("scripts.consts")

local Customization = {}

--- @class (exact) Customization
--- @field shortcuts ShortcutName[]
--- @field hidden_shortcuts ShortcutName[]

--- @class (exact) SerializedCustomization
--- @field s ShortcutName[] shortcuts
--- @field h ShortcutName[] hidden_shortcuts

--- @param customization Customization
--- @return string
function Customization.to_json(customization)
  --- @type SerializedCustomization
  local serialized = {
    s = customization.shortcuts,
    h = customization.hidden_shortcuts,
  }
  return helpers.table_to_json(serialized)
end

--- @param json_string string
--- @return Customization|nil
function Customization.from_json(json_string)
  local parsed = helpers.json_to_table(json_string)
  if not parsed then return nil end

  if type(parsed) ~= "table" then
    return nil
  end
  if type(parsed.s) ~= "table" then
    return nil
  end
  if type(parsed.h) ~= "table" then
    return nil
  end

  return {
    shortcuts = parsed.s,
    hidden_shortcuts = parsed.h,
  }
end

--- Load Customization from settings
---
--- Stage: runtime
---
--- @return Customization
function Customization.from_settings()
  local json = settings.startup[consts.CUSTOMIZE_JSON_SETTING_NAME]
  if not json or json.value == "" then
    return Customization.empty()
  end

  local customization = Customization.from_json(tostring(json.value))
  if not customization then
    log("[Quick Panel Tools Customize] Customize JSON is invalid.")
    return Customization.empty()
  end

  return customization --[[@as Customization]]
end

--- @return Customization
function Customization.empty()
  return {
    shortcuts = {},
    hidden_shortcuts = {},
  }
end

return Customization
