package.path = ("./lua/?.lua;" .. package.path)
if not _G.vim then
  local function _1_(_, t1, t2)
    local result = {}
    for k, v in pairs(t1) do
      result[k] = v
    end
    for k, v in pairs(t2) do
      result[k] = v
    end
    return result
  end
  local function _2_(str, prefix)
    return (str:sub(1, #prefix) == prefix)
  end
  _G.vim = {tbl_deep_extend = _1_, startswith = _2_}
else
end
local function _4_()
  return "/tmp/test-nvim-cache"
end
package.loaded["kaza.file"] = {["nvim-cache"] = _4_}
local M = require("sm.links")
assert((M["parse-link"]("[[memo-name]]") == "memo-name"), "parse: simple link")
assert((M["parse-link"]("[[20260117_test]]") == "20260117_test"), "parse: timestamp link")
assert((M["parse-link"]("text [[link]] more") == "link"), "parse: link in text")
assert((M["parse-link"]("[[my memo title]]") == "my memo title"), "parse: link with spaces")
assert((M["parse-link"]("no link here") == nil), "parse: no link")
assert((M["parse-link"]("[single bracket]") == nil), "parse: single brackets")
assert((M["parse-link"]("[[]]") == nil), "parse: empty link")
assert((M["parse-link"]("[[unclosed") == nil), "parse: unclosed link")
assert((M["parse-link"]("[[first]] and [[second]]") == "first"), "parse: multiple links")
return print("links_test.lua: All tests passed")
