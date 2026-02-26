local event_handler = require("__core__.lualib.event_handler")

event_handler.add_libraries({
  require("scripts.control.shortcut-control"),
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
  },
})
