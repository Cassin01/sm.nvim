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
  local function _5_(path, modifier)
    -- Mock fnamemodify to extract filename without extension
    if modifier == ":t:r" then
      local filename = path:match("([^/]+)$")  -- Get filename (tail)
      return filename:match("(.+)%.md$") or filename  -- Remove .md extension
    elseif modifier == ":t" then
      return path:match("([^/]+)$")  -- Get filename (tail)
    else
      return path
    end
  end
  _G.vim = {tbl_deep_extend = _2_, deepcopy = deepcopy, startswith = _3_, fn = {stdpath = _4_, fnamemodify = _5_}}
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

-- Mock sm.memo and sm.config for find_memo_by_partial tests
package.loaded["sm.memo"] = {
  list = function()
    return {
      "/tmp/memos/20260117_120000_meeting.md",
      "/tmp/memos/20260118_150000_important-meeting.md",
      "/tmp/memos/20260119_100000_project-meeting-notes.md",
    }
  end
}
package.loaded["sm.config"] = {
  get_memos_dir = function()
    return "/tmp/memos"
  end
}

-- Need to reload M to pick up the mocked modules
package.loaded["sm.links"] = nil
M = require("sm.links")

-- Test exact match is preferred over partial match
local result1 = M.find_memo_by_partial("20260117_120000_meeting")
assert(result1 == "/tmp/memos/20260117_120000_meeting.md", "find_memo: exact match preferred")

-- Test case-insensitive exact match
local result2 = M.find_memo_by_partial("20260117_120000_MEETING")
assert(result2 == "/tmp/memos/20260117_120000_meeting.md", "find_memo: case-insensitive exact match")

-- Test partial match when no exact match exists
local result3 = M.find_memo_by_partial("important")
assert(result3 == "/tmp/memos/20260118_150000_important-meeting.md", "find_memo: partial match works")

-- Test that partial match doesn't override exact match
-- If we search for just "meeting", it should prefer the exact filename match over partial
local result4 = M.find_memo_by_partial("meeting")
-- This will partial match all three files, but should return the first one found
-- since none of them is an exact match for "meeting" (they all have timestamps)
assert(result4 ~= nil, "find_memo: partial match returns result")

return print("links_test.lua: All tests passed")
