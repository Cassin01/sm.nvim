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
  local function _3_(msg, level)
    return nil
  end
  local function _4_(name, opts)
    return 1
  end
  local function _5_(events, opts)
    return nil
  end
  local function _6_(which)
    return "/tmp/test-nvim-cache"
  end
  _G.vim = {tbl_deep_extend = _2_, deepcopy = deepcopy, notify = _3_, log = {levels = {DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4}}, api = {nvim_create_augroup = _4_, nvim_create_autocmd = _5_}, fn = {stdpath = _6_}}
else
end
local function _8_()
  return nil
end
package.loaded["sm.cmd"] = {setup = _8_}
local function _9_()
  return nil
end
package.loaded["sm.links"] = {setup_buffer_mappings = _9_}
local M = require("sm.init")
do
  local pattern = M.autocmd_pattern()
  assert((pattern ~= nil), "autocmd_pattern: returns value")
  assert(pattern:find("/%*%.md$"), "autocmd_pattern: ends with /*.md")
end
do
  local pattern = M.autocmd_pattern()
  assert(pattern:find("/memos/"), "autocmd_pattern: includes memos directory")
end
return print("init_test.lua: All tests passed")
