--- Stage: runtime

local consts = require("scripts.consts")

--- @class Metatable
local Metatable = {
  --- Metatable for making table keys weak references
  weak_key_metatable = { __mode = "k" },
}

script.register_metatable(consts.name("Metatable.weak_key"), Metatable.weak_key_metatable)

return Metatable
