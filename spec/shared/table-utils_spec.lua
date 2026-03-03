local TableUtils = require("scripts.shared.table-utils")

describe("TableUtils", function ()
  describe("shallow_copy", function ()
    it("copies empty table", function ()
      local original = {}
      local copy = TableUtils.shallow_copy(original)

      assert.are_not_equal(original, copy)
      assert.is_true(next(copy) == nil) -- Check if table is empty
    end)

    it("copies simple table", function ()
      local original = { a = 1, b = 2, c = 3 }
      local copy = TableUtils.shallow_copy(original)

      assert.are_not_equal(original, copy)
      assert.are_equal(1, copy.a)
      assert.are_equal(2, copy.b)
      assert.are_equal(3, copy.c)
    end)

    it("copies array", function ()
      local original = { 1, 2, 3 }
      local copy = TableUtils.shallow_copy(original)

      assert.are_not_equal(original, copy)
      assert.are_equal(1, copy[1])
      assert.are_equal(2, copy[2])
      assert.are_equal(3, copy[3])
    end)

    it("does not deep copy nested tables", function ()
      local nested = { x = 1 }
      local original = { nested = nested }
      local copy = TableUtils.shallow_copy(original)

      assert.are_not_equal(original, copy)
      assert.are_equal(original.nested, copy.nested)

      -- Modify nested table through copy
      copy.nested.x = 99
      assert.are_equal(99, original.nested.x)
    end)
  end)

  describe("merge", function ()
    it("merges empty tables", function ()
      local result = TableUtils.merge({}, {})
      assert.is_true(next(result) == nil) -- Check if table is empty
    end)

    it("merges first table into empty", function ()
      local tbl1 = { a = 1, b = 2 }
      local result = TableUtils.merge(tbl1, {})

      assert.are_equal(1, result.a)
      assert.are_equal(2, result.b)
    end)

    it("merges second table into empty", function ()
      local tbl2 = { a = 1, b = 2 }
      local result = TableUtils.merge({}, tbl2)

      assert.are_equal(1, result.a)
      assert.are_equal(2, result.b)
    end)

    it("merges two tables", function ()
      local tbl1 = { a = 1, b = 2 }
      local tbl2 = { c = 3, d = 4 }
      local result = TableUtils.merge(tbl1, tbl2)

      assert.are_equal(1, result.a)
      assert.are_equal(2, result.b)
      assert.are_equal(3, result.c)
      assert.are_equal(4, result.d)
    end)

    it("second table overwrites first table values", function ()
      local tbl1 = { a = 1, b = 2, c = 3 }
      local tbl2 = { b = 99, d = 4 }
      local result = TableUtils.merge(tbl1, tbl2)

      assert.are_equal(1, result.a)
      assert.are_equal(99, result.b) -- overwritten
      assert.are_equal(3, result.c)
      assert.are_equal(4, result.d)
    end)

    it("does not modify original tables", function ()
      local tbl1 = { a = 1, b = 2 }
      local tbl2 = { b = 99, c = 3 }
      TableUtils.merge(tbl1, tbl2)

      assert.are_equal(1, tbl1.a)
      assert.are_equal(2, tbl1.b)
      assert.are_equal(99, tbl2.b)
      assert.are_equal(3, tbl2.c)
    end)
  end)

  describe("keys", function ()
    it("returns empty array for empty table", function ()
      local result = TableUtils.keys({})
      assert.is_true(next(result) == nil) -- Check if table is empty
    end)

    it("returns keys from simple table", function ()
      local tbl = { a = 1, b = 2, c = 3 }
      local result = TableUtils.keys(tbl)

      assert.are_equal(3, #result)
      -- Check that all keys are present (order may vary)
      local found_a, found_b, found_c = false, false, false
      for _, key in ipairs(result) do
        if key == "a" then found_a = true end
        if key == "b" then found_b = true end
        if key == "c" then found_c = true end
      end
      assert.is_true(found_a)
      assert.is_true(found_b)
      assert.is_true(found_c)
    end)

    it("returns keys from array", function ()
      local tbl = { 10, 20, 30 }
      local result = TableUtils.keys(tbl)

      assert.are_equal(3, #result)
      -- Check that all keys are present (order may vary)
      local found_1, found_2, found_3 = false, false, false
      for _, key in ipairs(result) do
        if key == 1 then found_1 = true end
        if key == 2 then found_2 = true end
        if key == 3 then found_3 = true end
      end
      assert.is_true(found_1)
      assert.is_true(found_2)
      assert.is_true(found_3)
    end)
  end)

  describe("values", function ()
    it("returns empty array for empty table", function ()
      local result = TableUtils.values({})
      assert.is_true(next(result) == nil) -- Check if table is empty
    end)

    it("returns values from simple table", function ()
      local tbl = { a = 1, b = 2, c = 3 }
      local result = TableUtils.values(tbl)

      assert.are_equal(3, #result)
      -- Check that all values are present (order may vary)
      local found_1, found_2, found_3 = false, false, false
      for _, value in ipairs(result) do
        if value == 1 then found_1 = true end
        if value == 2 then found_2 = true end
        if value == 3 then found_3 = true end
      end
      assert.is_true(found_1)
      assert.is_true(found_2)
      assert.is_true(found_3)
    end)

    it("returns values from array", function ()
      local tbl = { 10, 20, 30 }
      local result = TableUtils.values(tbl)

      assert.are_equal(3, #result)
      -- Check that all values are present (order may vary)
      local found_10, found_20, found_30 = false, false, false
      for _, value in ipairs(result) do
        if value == 10 then found_10 = true end
        if value == 20 then found_20 = true end
        if value == 30 then found_30 = true end
      end
      assert.is_true(found_10)
      assert.is_true(found_20)
      assert.is_true(found_30)
    end)

    it("handles duplicate values", function ()
      local tbl = { a = 1, b = 1, c = 1 }
      local result = TableUtils.values(tbl)

      assert.are_equal(3, #result)
      assert.are_equal(1, result[1])
      assert.are_equal(1, result[2])
      assert.are_equal(1, result[3])
    end)
  end)
end)
