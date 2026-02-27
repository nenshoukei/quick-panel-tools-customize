local utils = {}

--- Checks if a table is an array (a table with sequence keys)
---
--- Copied from https://stackoverflow.com/a/52697380
---
--- @param tbl table
--- @return boolean result Whether tbl is an array (sequence keys) or not
function utils.is_array(tbl)
  if type(tbl) ~= "table" then
    return false
  end

  -- objects always return empty size
  if #tbl > 0 then
    return true
  end

  -- only object can have empty length with elements inside
  for _ in pairs(tbl) do
    return false
  end

  -- if no elements it can be array and not at same time
  return true
end

--- Shallow copy of a table
---
--- @generic T : table
--- @param tbl T
--- @return T
function utils.table_shallow_copy(tbl)
  local result = {}
  for k, v in pairs(tbl) do
    result[k] = v
  end
  return result
end

--- Merge two tables with non-sequential keys into one
---
--- @param tbl1 table
--- @param tbl2 table
--- @return table
function utils.table_merge(tbl1, tbl2)
  local result = {}
  for k, v in pairs(tbl1) do
    result[k] = v
  end
  for k, v in pairs(tbl2) do
    result[k] = v
  end
  return result
end

--- Returns an array of keys from a table
---
--- @generic K, V
--- @param tbl table<K, V>
--- @return K[]
function utils.table_keys(tbl)
  local result = {}
  for k, _ in pairs(tbl) do
    result[#result + 1] = k
  end
  return result
end

--- Returns an array of values from a table
---
--- @generic K, V
--- @param tbl table<K, V>
--- @return V[]
function utils.table_values(tbl)
  local result = {}
  for _, v in pairs(tbl) do
    result[#result + 1] = v
  end
  return result
end

return utils
