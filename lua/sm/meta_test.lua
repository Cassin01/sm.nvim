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
  local function _4_(path, modifier)
    return path
  end
  local function _5_(listed, scratch)
    return 1
  end
  local function _6_(buf, start, _end, strict, lines)
    return nil
  end
  local function _7_(buf, opt, val)
    return nil
  end
  local function _8_(buf, enter, opts)
    return 1
  end
  local function _9_(buf, mode, lhs, rhs, opts)
    return nil
  end
  local function _10_(win, force)
    return nil
  end
  _G.vim = {tbl_deep_extend = _2_, deepcopy = deepcopy, fn = {stdpath = _3_, fnamemodify = _4_}, api = {nvim_create_buf = _5_, nvim_buf_set_lines = _6_, nvim_buf_set_option = _7_, nvim_open_win = _8_, nvim_buf_set_keymap = _9_, nvim_win_close = _10_}, o = {columns = 120, lines = 40}}
else
end
local function _12_()
  return {"/tmp/memos/20260101_120000_first-memo.md", "/tmp/memos/20260102_130000_second-memo.md", "/tmp/memos/20260103_140000_third-memo.md"}
end
package.loaded["sm.memo"] = {list = _12_}
local function _13_()
  return {{tag = "todo", count = 5}, {tag = "work", count = 3}, {tag = "ideas", count = 1}}
end
local function _14_()
  return {"ideas", "todo", "work"}
end
package.loaded["sm.tags"] = {get_tags_with_counts = _13_, list_all_tags = _14_}
local function _15_(_3flimit)
  return {"first.md", "second.md"}
end
local function _16_()
  return "/tmp/memos/20260103_140000_third-memo.md"
end
package.loaded["sm.state"] = {get_recent = _15_, get_last_edited = _16_}
local function _17_()
  return {window = {width = 80, height = 30, border = "rounded", style = "minimal"}}
end
local function _18_()
  return "/tmp/memos"
end
package.loaded["sm.config"] = {get = _17_, get_memos_dir = _18_}
local M = require("sm.meta")
do
  local stats = M.get_statistics()
  assert((type(stats) == "table"), "get_statistics: returns table")
  assert((stats.total_memos == 3), "get_statistics: total_memos count")
  assert((stats.total_tags == 3), "get_statistics: total_tags count")
  assert((stats.recent_count == 2), "get_statistics: recent_count")
  assert((type(stats.top_tags) == "table"), "get_statistics: top_tags is table")
  assert((#stats.top_tags == 3), "get_statistics: top_tags count")
  assert((stats.top_tags[1].tag == "todo"), "get_statistics: top tag is todo")
end
do
  local stats = {total_memos = 150, total_tags = 5, recent_count = 20, top_tags = {{tag = "todo", count = 50}}}
  local analysis = M.get_behavior_analysis(stats)
  assert((type(analysis) == "table"), "get_behavior_analysis: returns table")
  assert((#analysis > 0), "get_behavior_analysis: has observations")
end
do
  local stats = {total_memos = 2, total_tags = 1, recent_count = 2, top_tags = {{tag = "test", count = 1}}}
  local analysis = M.get_behavior_analysis(stats)
  assert((type(analysis) == "table"), "get_behavior_analysis: handles few memos")
end
do
  local lines = M.generate_meta_content()
  assert((type(lines) == "table"), "generate_meta_content: returns table")
  assert((#lines > 0), "generate_meta_content: has content")
  assert((lines[1] == "# The Memo Knows"), "generate_meta_content: has title")
end
do
  local lines = M.generate_meta_content()
  local content = table.concat(lines, "\n")
  assert(content:find("Total memos"), "generate_meta_content: includes total memos")
  assert(content:find("3"), "generate_meta_content: shows memo count")
  assert(content:find("todo"), "generate_meta_content: includes top tag")
end
return print("meta_test.lua: All tests passed")
