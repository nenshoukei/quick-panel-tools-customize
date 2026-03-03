local TableUtils = {}

--- Shallow copy of a table
---
--- @generic T : table
--- @param tbl T
--- @return T
function TableUtils.shallow_copy(tbl)
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
function TableUtils.merge(tbl1, tbl2)
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
function TableUtils.keys(tbl)
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
function TableUtils.values(tbl)
  local result = {}
  for _, v in pairs(tbl) do
    result[#result + 1] = v
  end
  return result
end

return TableUtils
