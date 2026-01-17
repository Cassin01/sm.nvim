local M = {}
local config = require("sm.config")
local function ensure_dir(path)
  if (vim.fn.isdirectory(path) == 0) then
    return vim.fn.mkdir(path, "p")
  else
    return nil
  end
end
local function read_json(filepath)
  local file, err = io.open(filepath, "r")
  if file then
    local content = file:read("*all")
    file:close()
    if (content and (#content > 0)) then
      return vim.fn.json_decode(content)
    else
      return {}
    end
  else
    return {}
  end
end
local function write_json(filepath, data)
  ensure_dir(vim.fn.fnamemodify(filepath, ":h"))
  local file, err = io.open(filepath, "w")
  if file then
    file:write(vim.fn.json_encode(data))
    file:close()
    return true
  else
    return nil
  end
end
M.load = function()
  return read_json(config["get-state-file"]())
end
M.save = function(state)
  return write_json(config["get-state-file"](), state)
end
M["get-last-edited"] = function()
  local state = M.load()
  if state.last_edited then
    return (config["get-memos-dir"]() .. "/" .. state.last_edited)
  else
    return nil
  end
end
M["set-last-edited"] = function(filename)
  local state = M.load()
  state["last_edited"] = filename
  state["last_accessed"] = os.time()
  return M.save(state)
end
M["get-recent"] = function(_3flimit)
  local state = M.load()
  local limit = (_3flimit or 10)
  return (state.recent or {})
end
M["add-recent"] = function(filename)
  local state = M.load()
  local recent = (state.recent or {})
  local filtered
  local function _6_(_241)
    return (_241 ~= filename)
  end
  filtered = vim.tbl_filter(_6_, recent)
  table.insert(filtered, 1, filename)
  while (#filtered > 20) do
    table.remove(filtered)
  end
  state["recent"] = filtered
  return M.save(state)
end
local method_name = ...
if (method_name == nil) then
  do
    local result = read_json("/tmp/sm_nonexistent_test.json")
    assert((type(result) == "table"), "read: returns table for missing file")
    assert((next(result) == nil), "read: returns empty table")
  end
  do
    local test_file = "/tmp/sm_test_state.json"
    local data = {test = "value", num = 42, nested = {a = 1}}
    assert(write_json(test_file, data), "write: returns true on success")
    do
      local loaded = read_json(test_file)
      assert((loaded.test == "value"), "roundtrip: string value")
      assert((loaded.num == 42), "roundtrip: number value")
      assert((loaded.nested.a == 1), "roundtrip: nested value")
    end
    os.remove(test_file)
  end
  do
    local test_file = "/tmp/sm_test_dir/nested/state.json"
    local data = {created = true}
    write_json(test_file, data)
    do
      local loaded = read_json(test_file)
      assert((loaded.created == true), "write: creates nested dirs")
    end
    os.remove(test_file)
    os.execute("rm -rf /tmp/sm_test_dir")
  end
  do
    local test_file = "/tmp/sm_empty_test.json"
    local file = io.open(test_file, "w")
    file:close()
    do
      local result = read_json(test_file)
      assert((type(result) == "table"), "read: handles empty file")
    end
    os.remove(test_file)
  end
  print("state.fnl: All tests passed")
else
end
return M
