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
  local function _3_(str, prefix)
    return (str:sub(1, #prefix) == prefix)
  end
  local function _4_(which)
    return "/tmp/test-nvim-cache"
  end
  _G.vim = {tbl_deep_extend = _2_, deepcopy = deepcopy, startswith = _3_, fn = {stdpath = _4_}}
else
end
local M = require("sm.links")
assert((M.parse_link("[[memo-name]]") == "memo-name"), "parse: simple link")
assert((M.parse_link("[[20260117_test]]") == "20260117_test"), "parse: timestamp link")
assert((M.parse_link("text [[link]] more") == "link"), "parse: link in text")
assert((M.parse_link("[[my memo title]]") == "my memo title"), "parse: link with spaces")
assert((M.parse_link("no link here") == nil), "parse: no link")
assert((M.parse_link("[single bracket]") == nil), "parse: single brackets")
assert((M.parse_link("[[]]") == nil), "parse: empty link")
assert((M.parse_link("[[unclosed") == nil), "parse: unclosed link")
assert((M.parse_link("[[first]] and [[second]]") == "first"), "parse: multiple links")
return print("links_test.lua: All tests passed")
