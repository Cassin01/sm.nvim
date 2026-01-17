package.path = ("./lua/?.lua;" .. package.path)
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
  local function _2_(_, t1, t2)
    local result = {}
    for k, v in pairs(t1) do
      result[k] = v
    end
    for k, v in pairs(t2) do
      result[k] = v
    end
    return result
  end
  local function _3_(path, modifier)
    if (modifier == ":t") then
      return path:match("([^/]+)$")
    else
      return path
    end
  end
  local function _5_(which)
    return "/tmp/test-nvim-cache"
  end
  _G.vim = {tbl_deep_extend = _2_, deepcopy = deepcopy, fn = {fnamemodify = _3_, stdpath = _5_}}
else
end
local function _7_()
end
local function _8_()
end
local function _9_()
  return {}
end
package.loaded["sm.state"] = {set_last_edited = _7_, add_recent = _8_, load = _9_}
local M = require("sm.memo")
assert((M._sanitize_title("Hello World!") == "hello-world"), "sanitize: spaces and punctuation")
assert((M._sanitize_title("  Test  ") == "test"), "sanitize: trim whitespace")
assert((M._sanitize_title("My--Title") == "my-title"), "sanitize: collapse dashes")
assert((M._sanitize_title("CamelCase") == "camelcase"), "sanitize: lowercase")
do
  local filename = M.generate_filename("test")
  assert(filename:match("^%d+_%d+_test%.md$"), "filename: format YYYYMMDD_HHMMSS_title.md")
end
do
  local content = M.generate_template("Test Title")
  assert(content:match("^%-%-%-"), "template: starts with frontmatter")
  assert(content:match("tags: %[%]"), "template: has empty tags")
  assert(content:match("# Test Title"), "template: has title heading")
end
do
  local info = M.get_memo_info("/path/to/20260117_143052_my-memo.md")
  assert((info.filename == "20260117_143052_my-memo.md"), "info: filename")
  assert((info.date == "20260117_143052"), "info: date")
  assert((info.title == "my memo"), "info: title with spaces")
end
return print("memo_test.lua: All tests passed")
