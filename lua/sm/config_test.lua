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
  local function _4_(which)
    return "/tmp/test-nvim-cache"
  end
  _G.vim = {tbl_deep_extend = _2_, deepcopy = deepcopy, notify = _3_, log = {levels = {DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4}}, fn = {stdpath = _4_}}
else
end
local M = require("sm.config")
M._reset()
M.setup({})
do
  local cfg = M.get()
  assert((cfg ~= nil), "get: auto-initializes config")
  assert((cfg.date_format == "%Y%m%d_%H%M%S"), "get: has default date-format")
end
M._reset()
M.setup({})
do
  local dir = M.get_memos_dir()
  assert((dir ~= nil), "get-memos-dir: returns value")
  assert(dir:find("/memos$"), "get-memos-dir: ends with /memos")
end
M._reset()
M.setup({})
do
  local file = M.get_state_file()
  assert((file ~= nil), "get-state-file: returns value")
  assert(file:find("/state%.json$"), "get-state-file: ends with /state.json")
end
M._reset()
M.setup({date_format = "%Y-%m-%d", custom_opt = "test"})
do
  local cfg = M.get()
  assert((cfg.date_format == "%Y-%m-%d"), "setup: overrides defaults")
  assert((cfg.custom_opt == "test"), "setup: adds custom options")
end
M._reset()
M.setup({memos_dir = "/custom/memos"})
assert((M.get_memos_dir() == "/custom/memos"), "get-memos-dir: respects custom path")
M._reset()
M.setup({state_file = "/custom/state.json"})
assert((M.get_state_file() == "/custom/state.json"), "get-state-file: respects custom path")
return print("config_test.lua: All tests passed")
