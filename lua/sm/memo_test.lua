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
local function _10_()
  return nil
end
local function _11_()
  return false
end
package.loaded["sm.git"] = {get_repo_tag = _10_, is_git_repo = _11_}
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
  local info = M.get_memo_info("/path/to/20260117_143052_my-memo.md")
  assert((info.filename == "20260117_143052_my-memo.md"), "info: filename")
  assert((info.date == "20260117_143052"), "info: date")
  assert((info.title == "my memo"), "info: title with spaces")
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
  local function _12_()
    return {auto_tag_git_repo = true, date_format = "%Y%m%d_%H%M%S", template = {"---", "tags: [%tags%]", "created: %date%", "---", "", "# %title%", ""}}
  end
  local function _13_()
    return "/tmp/test-memos"
  end
  package.loaded["sm.config"] = {get = _12_, get_memos_dir = _13_}
  local function _14_()
    return "test-repo"
  end
  local function _15_()
    return true
  end
  package.loaded["sm.git"] = {get_repo_tag = _14_, is_git_repo = _15_}
  local function _16_()
  end
  local function _17_()
  end
  local function _18_()
    return {}
  end
  package.loaded["sm.state"] = {set_last_edited = _16_, add_recent = _17_, load = _18_}
  local M2 = require("sm.memo")
  do
    local tags = M2._get_initial_tags()
    assert((#tags == 1), "auto_tag: returns one tag")
    assert((tags[1] == "test-repo"), "auto_tag: returns correct repo name")
  end
  local content = M2.generate_template("Test", M2._get_initial_tags())
  assert(content:match("tags: %[test%-repo%]"), "auto_tag: template includes repo tag")
end
return print("memo_test.lua: All tests passed")
