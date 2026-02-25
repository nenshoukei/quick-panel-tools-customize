local event_handler = require("__core__.lualib.event_handler")

event_handler.add_libraries({
  require("scripts.gui.customize-gui"),
  {
    on_init = function ()
      local freeplay = remote.interfaces["freeplay"]
      if freeplay then -- Disable freeplay popup-message
        if freeplay["set_skip_intro"] then remote.call("freeplay", "set_skip_intro", true) end
        if freeplay["set_disable_crashsite"] then remote.call("freeplay", "set_disable_crashsite", true) end
      end
    end,
  },
})

if script.active_mods["gvv"] then require("__gvv__.gvv")() end
