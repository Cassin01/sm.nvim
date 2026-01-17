package.path = ("./lua/?.lua;" .. package.path)
local function json_encode(data)
  if (type(data) == "table") then
    local is_array = true
    local i = 1
    for k, _ in pairs(data) do
      if (k ~= i) then
        is_array = false
      else
      end
      i = (i + 1)
    end
    if is_array then
      local _2_
      do
        local tbl_26_ = {}
        local i_27_ = 0
        for _, v in ipairs(data) do
          local val_28_ = json_encode(v)
          if (nil ~= val_28_) then
            i_27_ = (i_27_ + 1)
            tbl_26_[i_27_] = val_28_
          else
          end
        end
        _2_ = tbl_26_
      end
      return ("[" .. table.concat(_2_, ",") .. "]")
    else
      local _4_
      do
        local tbl_26_ = {}
        local i_27_ = 0
        for k, v in pairs(data) do
          local val_28_ = ("\"" .. tostring(k) .. "\":" .. json_encode(v))
          if (nil ~= val_28_) then
            i_27_ = (i_27_ + 1)
            tbl_26_[i_27_] = val_28_
          else
          end
        end
        _4_ = tbl_26_
      end
      return ("{" .. table.concat(_4_, ",") .. "}")
    end
  elseif (type(data) == "string") then
    return ("\"" .. data .. "\"")
  elseif (type(data) == "number") then
    return tostring(data)
  elseif (type(data) == "boolean") then
    if data then
      return "true"
    else
      return "false"
    end
  else
    return "null"
  end
end
local function json_decode(str)
  local result = str:gsub("{", "<<<LBRACE>>>"):gsub("}", "<<<RBRACE>>>"):gsub("%[", "<<<LBRACK>>>"):gsub("%]", "<<<RBRACK>>>")
  local function _9_(key)
    return ("<<<LBRACK>>>\"" .. key .. "\"<<<RBRACK>>>=")
  end
  result = string.gsub(result, "\"([^\"]+)\":", _9_)
  result = result:gsub("=true", "=true"):gsub("=false", "=false"):gsub("=null", "=nil")
  result = result:gsub("<<<LBRACE>>>", "{"):gsub("<<<RBRACE>>>", "}"):gsub("<<<LBRACK>>>", "["):gsub("<<<RBRACK>>>", "]")
  local func = load(("return " .. result))
  return func()
end
if not _G.vim then
  local function deepcopy(t)
    if (type(t) == "table") then
      local copy = {}
      for k, v in pairs(t) do
        copy[k] = deepcopy(v)
      end
      return copy
    else
      return t
    end
  end
  local function _11_(_, t1, t2)
    local result = {}
    for k, v in pairs(t1) do
      result[k] = v
    end
    for k, v in pairs(t2) do
      result[k] = v
    end
    return result
  end
  local function _12_(path)
    local handle, err = io.open((path .. "/."))
    if handle then
      handle:close()
      return 1
    else
      return 0
    end
  end
  local function _14_(path, mode)
    return os.execute(("mkdir -p \"" .. path .. "\""))
  end
  local function _15_(path, modifier)
    if (modifier == ":h") then
      return (path:match("(.+)/[^/]+$") or ".")
    else
      return path
    end
  end
  local function _17_(which)
    return "/tmp/test-nvim-cache"
  end
  _G.vim = {tbl_deep_extend = _11_, deepcopy = deepcopy, fn = {isdirectory = _12_, mkdir = _14_, fnamemodify = _15_, json_decode = json_decode, json_encode = json_encode, stdpath = _17_}}
else
end
local M = require("sm.state")
do
  local result = M["_read-json"]("/tmp/sm_nonexistent_test.json")
  assert((type(result) == "table"), "read: returns table for missing file")
  assert((next(result) == nil), "read: returns empty table")
end
do
  local test_file = "/tmp/sm_test_state.json"
  local data = {test = "value", num = 42, nested = {a = 1}}
  assert(M["_write-json"](test_file, data), "write: returns true on success")
  do
    local loaded = M["_read-json"](test_file)
    assert((loaded.test == "value"), "roundtrip: string value")
    assert((loaded.num == 42), "roundtrip: number value")
    assert((loaded.nested.a == 1), "roundtrip: nested value")
  end
  os.remove(test_file)
end
do
  local test_file = "/tmp/sm_test_dir/nested/state.json"
  local data = {created = true}
  M["_write-json"](test_file, data)
  do
    local loaded = M["_read-json"](test_file)
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
    local result = M["_read-json"](test_file)
    assert((type(result) == "table"), "read: handles empty file")
  end
  os.remove(test_file)
end
return print("state_test.lua: All tests passed")
