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
  local function _6_(filepath)
    return {mtime = {sec = 1737200000}}
  end
  _G.vim = {tbl_deep_extend = _2_, deepcopy = deepcopy, fn = {fnamemodify = _3_, stdpath = _5_}, uv = {fs_stat = _6_}}
else
end
local function _8_()
end
local function _9_()
end
local function _10_()
  return {}
end
package.loaded["sm.state"] = {set_last_edited = _8_, add_recent = _9_, load = _10_}
local function _11_()
  return nil
end
local function _12_()
  return false
end
package.loaded["sm.git"] = {get_repo_tag = _11_, is_git_repo = _12_}
local M = require("sm.memo")
assert((M._sanitize_title("Hello World!") == "hello-world"), "sanitize: spaces and punctuation")
assert((M._sanitize_title("  Test  ") == "test"), "sanitize: trim whitespace")
assert((M._sanitize_title("My--Title") == "my-title"), "sanitize: collapse dashes")
assert((M._sanitize_title("CamelCase") == "camelcase"), "sanitize: lowercase")
assert((M._sanitize_title("\230\151\165\230\156\172\232\170\158") == "\230\151\165\230\156\172\232\170\158"), "sanitize: preserve Japanese")
assert((M._sanitize_title("\230\151\165\230\156\172\232\170\158 Test") == "\230\151\165\230\156\172\232\170\158-test"), "sanitize: Japanese with ASCII")
assert((M._sanitize_title("\232\168\152\229\143\183\239\188\129\227\131\134\227\130\185\227\131\136") == "\232\168\152\229\143\183\239\188\129\227\131\134\227\130\185\227\131\136"), "sanitize: preserve full-width punctuation")
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
  local ts = M._parse_date_to_timestamp("20260117_143052")
  assert(ts, "parse_date: returns non-nil for valid date")
  assert((type(ts) == "number"), "parse_date: returns a number")
  local d = os.date("*t", ts)
  assert((d.year == 2026), "parse_date: correct year")
  assert((d.month == 1), "parse_date: correct month")
  assert((d.day == 17), "parse_date: correct day")
  assert((d.hour == 14), "parse_date: correct hour")
  assert((d.min == 30), "parse_date: correct min")
  assert((d.sec == 52), "parse_date: correct sec")
end
assert((M._parse_date_to_timestamp(nil) == nil), "parse_date: nil input returns nil")
assert((M._parse_date_to_timestamp("invalid") == nil), "parse_date: invalid input returns nil")
do
  local info = M.get_memo_info("/path/to/20260117_143052_my-memo.md")
  assert((info.filename == "20260117_143052_my-memo.md"), "info: filename")
  assert((info.date == "20260117_143052"), "info: date")
  assert((info.title == "my memo"), "info: title with spaces")
  assert(info.created_at, "info: has created_at")
  assert((type(info.created_at) == "number"), "info: created_at is number")
  assert(info.updated_at, "info: has updated_at")
  assert((info.updated_at == 1737200000), "info: updated_at from fs_stat mtime")
end
do
  local content = M.generate_template("Test", {"tag1", "tag2"})
  assert(content:match("tags: %[tag1, tag2%]"), "template: includes initial tags")
end
do
  local content = M.generate_template("Test", {})
  assert(content:match("tags: %[%]"), "template: empty tags when none provided")
end
do
  local content = M.generate_template("Test")
  assert(content:match("tags: %[%]"), "template: empty tags when nil provided")
end
do
  package.loaded["sm.config"] = nil
  package.loaded["sm.git"] = nil
  package.loaded["sm.memo"] = nil
  local function _13_()
    return {auto_tag_git_repo = true, date_format = "%Y%m%d_%H%M%S", template = {"---", "tags: [%tags%]", "created: %date%", "---", "", "# %title%", ""}}
  end
  local function _14_()
    return "/tmp/test-memos"
  end
  package.loaded["sm.config"] = {get = _13_, get_memos_dir = _14_}
  local function _15_()
    return "test-repo"
  end
  local function _16_()
    return true
  end
  package.loaded["sm.git"] = {get_repo_tag = _15_, is_git_repo = _16_}
  local function _17_()
  end
  local function _18_()
  end
  local function _19_()
    return {}
  end
  package.loaded["sm.state"] = {set_last_edited = _17_, add_recent = _18_, load = _19_}
  local M2 = require("sm.memo")
  do
    local tags = M2._get_initial_tags()
    assert((#tags == 1), "auto_tag: returns one tag")
    assert((tags[1] == "test-repo"), "auto_tag: returns correct repo name")
  end
  local content = M2.generate_template("Test", M2._get_initial_tags())
  assert(content:match("tags: %[test%-repo%]"), "auto_tag: template includes repo tag")
end
do
  package.loaded["sm.config"] = nil
  package.loaded["sm.git"] = nil
  package.loaded["sm.memo"] = nil
  local set_current_buf_calls = {}
  local cmd_calls = {}
  local open_win_calls = {}
  if not _G.vim.api then
    _G.vim.api = {}
  else
  end
  local function _21_(buf)
    return table.insert(set_current_buf_calls, buf)
  end
  _G.vim.api["nvim_set_current_buf"] = _21_
  local function _22_(buf, enter, opts)
    table.insert(open_win_calls, {buf = buf, enter = enter, opts = opts})
    return 1
  end
  _G.vim.api["nvim_open_win"] = _22_
  local function _23_()
    return {date_format = "%Y%m%d_%H%M%S", template = {"---", "# %title%", ""}, copilot_integration = false}
  end
  local function _24_()
    return "/tmp/test-memos"
  end
  package.loaded["sm.config"] = {get = _23_, get_memos_dir = _24_}
  local function _25_()
    return nil
  end
  local function _26_()
    return false
  end
  package.loaded["sm.git"] = {get_repo_tag = _25_, is_git_repo = _26_}
  local function _27_()
  end
  local function _28_()
  end
  local function _29_()
    return {}
  end
  package.loaded["sm.state"] = {set_last_edited = _27_, add_recent = _28_, load = _29_}
  local function _30_(filepath)
    return 42
  end
  _G.vim.fn["bufadd"] = _30_
  local function _31_(buf)
    return nil
  end
  _G.vim.fn["bufload"] = _31_
  local function _32_()
    return {}
  end
  _G.vim.bo = setmetatable({}, {__index = _32_})
  local function _33_()
    return {}
  end
  _G.vim.wo = setmetatable({}, {__index = _33_})
  local function _34_(cmd)
    return table.insert(cmd_calls, cmd)
  end
  _G.vim["cmd"] = _34_
  local M3 = require("sm.memo")
  local buf = M3.open_in_buffer("/tmp/test-memos/test.md")
  assert((#set_current_buf_calls == 1), "open_in_buffer: nvim_set_current_buf called once")
  assert((set_current_buf_calls[1] == 42), "open_in_buffer: correct buffer id passed")
  local has_split = false
  for _, cmd in ipairs(cmd_calls) do
    if cmd:match("split") then
      has_split = true
    else
    end
  end
  assert(not has_split, "open_in_buffer: no split command issued")
  assert((#open_win_calls == 0), "open_in_buffer: nvim_open_win not called")
  assert((buf == 42), "open_in_buffer: returns buffer id")
end
return print("memo_test.lua: All tests passed")
