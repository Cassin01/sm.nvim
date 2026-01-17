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
  local function _3_(which)
    return "/tmp/test-nvim-cache"
  end
  _G.vim = {tbl_deep_extend = _2_, deepcopy = deepcopy, fn = {stdpath = _3_}}
else
end
local M = require("sm.tags")
do
  local content = "---\ntags: [work, ideas]\ncreated: 2026-01-17\n---\n# Test"
  local result = M["parse-frontmatter"](content)
  assert((#result.tags == 2), "parse: tag count")
  assert((result.tags[1] == "work"), "parse: first tag")
  assert((result.tags[2] == "ideas"), "parse: second tag")
  assert((result.created == "2026-01-17"), "parse: created date")
end
do
  local content = "---\ntags: []\ncreated: 2026-01-17\n---\n# Test"
  local result = M["parse-frontmatter"](content)
  assert((#result.tags == 0), "parse: empty tags")
end
do
  local result = M["parse-frontmatter"]("No frontmatter here")
  assert((#result.tags == 0), "parse: no frontmatter")
  assert((result.created == nil), "parse: no created")
end
do
  local content = "---\ntags: [ tag1 , tag2 , tag3 ]\n---\n"
  local result = M["parse-frontmatter"](content)
  assert((#result.tags == 3), "parse: tags with spaces")
  assert((result.tags[1] == "tag1"), "parse: trimmed tag")
end
return print("tags_test.lua: All tests passed")
