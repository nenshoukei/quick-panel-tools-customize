local event_handler = require("__core__.lualib.event_handler")
local consts = require("scripts.consts")

event_handler.add_libraries({
  require("scripts.gui.customize-gui"),
  {
    on_init = function ()
      if script.active_mods["debugadapter"] then
        -- For debugging: Skip intro and crashsite
        local freeplay = remote.interfaces["freeplay"]
        if freeplay then
          if freeplay["set_skip_intro"] then remote.call("freeplay", "set_skip_intro", true) end
          if freeplay["set_disable_crashsite"] then remote.call("freeplay", "set_disable_crashsite", true) end
        end
      end
    end,

    on_load = function ()
      -- Make placeholder shortcuts unavailable
      local mod_data = prototypes.mod_data[consts.SHORTCUT_LIST_DATA_NAME]
      local shortcut_list_data = assert(mod_data and mod_data.data, "mod-data not found") --[[@as ShortcutListModData]]
      for _, index in ipairs(shortcut_list_data.placeholder_indexes) do
        for _, player in pairs(game.players) do
          player.set_shortcut_available(consts.PLACEHOLDER_SHORTCUT_NAME_PREFIX .. index, false)
        end
      end
    end,
  },
})

if script.active_mods["gvv"] then require("__gvv__.gvv")() end
