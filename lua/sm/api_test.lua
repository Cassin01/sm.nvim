package.path = ("./lua/?.lua;" .. package.path)
local last_open_memo_call = nil
local last_nvim_put_call = nil
if not _G.vim then
  local function _1_(path, modifier)
    if (modifier == ":t:r") then
      local basename = path:match("([^/]+)$")
      return basename:match("(.+)%.md$")
    elseif (modifier == ":t") then
      return path:match("([^/]+)$")
    else
      return path
    end
  end
  local function _3_(lines, mode, after, follow)
    last_nvim_put_call = {lines = lines, mode = mode}
    return nil
  end
  _G.vim = {fn = {fnamemodify = _1_}, api = {nvim_put = _3_}}
else
end
local function _5_()
  return {"/tmp/memos/20260117_120000_first-memo.md", "/tmp/memos/20260116_100000_second-memo.md"}
end
local function _6_(filepath)
  local filename = filepath:match("([^/]+)$")
  local date_part = filename:match("^(%d+_%d+)_")
  local title_part = filename:match("^%d+_%d+_(.+)%.md$"):gsub("-", " ")
  return {filepath = filepath, filename = filename, date = date_part, title = title_part}
end
local function _7_(filepath)
  last_open_memo_call = filepath
  return true
end
package.loaded["sm.memo"] = {list = _5_, ["get_memo_info"] = _6_, open = _7_}
local function _8_(filepath)
  if filepath:match("first") then
    return {"work", "ideas"}
  else
    return {}
  end
end
local function _10_()
  return {{tag = "work", count = 3}, {tag = "ideas", count = 2}}
end
local function _11_(tag)
  if (tag == "work") then
    return {"/tmp/memos/20260117_120000_first-memo.md"}
  else
    return {}
  end
end
package.loaded["sm.tags"] = {["get_memo_tags"] = _8_, ["get_tags_with_counts"] = _10_, ["get_memos_by_tag"] = _11_}
local function _13_()
  return "/tmp/test-memos"
end
package.loaded["sm.config"] = {["get_memos_dir"] = _13_}
local api = require("sm.api")
do
  local memos = api.get_memos()
  assert((#memos == 2), "get_memos: returns 2 entries")
  do
    local first_entry = memos[1]
    assert(first_entry.value, "get_memos: entry has value")
    assert(first_entry.text, "get_memos: entry has text")
    assert(first_entry.ordinal, "get_memos: entry has ordinal")
    assert(first_entry.info, "get_memos: entry has info")
    assert(first_entry.tags, "get_memos: entry has tags")
    assert(first_entry.text:match("%[work, ideas%]"), "get_memos: text includes tags")
    assert((#first_entry.tags == 2), "get_memos: first entry has 2 tags")
  end
  local second_entry = memos[2]
  assert(not second_entry.text:match("%["), "get_memos: no brackets when no tags")
  assert((#second_entry.tags == 0), "get_memos: second entry has 0 tags")
end
do
  local tags = api.get_tags()
  assert((#tags == 2), "get_tags: returns 2 entries")
  local first_tag = tags[1]
  assert((first_tag.value == "work"), "get_tags: value is tag name")
  assert((first_tag.count == 3), "get_tags: count is present")
  assert(first_tag.text:match("work"), "get_tags: text includes tag name")
  assert(first_tag.text:match("%(3 memos%)"), "get_tags: text includes count")
end
do
  local memos = api.get_memos_by_tag("work")
  assert((#memos == 1), "get_memos_by_tag: returns 1 entry for 'work'")
  local entry = memos[1]
  assert(entry.value, "get_memos_by_tag: entry has value")
  assert(entry.text, "get_memos_by_tag: entry has text")
  assert(entry.info, "get_memos_by_tag: entry has info")
end
do
  local empty_memos = api.get_memos_by_tag("nonexistent")
  assert((#empty_memos == 0), "get_memos_by_tag: returns empty for unknown tag")
end
do
  local links = api.get_memos_for_link()
  assert((#links == 2), "get_memos_for_link: returns 2 entries")
  local entry = links[1]
  assert((entry.value == "20260117_120000_first-memo"), "get_memos_for_link: value is filename without ext")
  assert(entry.text, "get_memos_for_link: entry has text")
  assert(entry.filepath, "get_memos_for_link: entry has filepath")
end
last_open_memo_call = nil
api.open_memo("/tmp/test/memo.md")
assert((last_open_memo_call == "/tmp/test/memo.md"), "open_memo: delegates to memo.open")
last_nvim_put_call = nil
api.insert_link("my-memo")
assert(last_nvim_put_call, "insert_link: calls nvim_put")
assert((last_nvim_put_call.lines[1] == "[[my-memo]]"), "insert_link: formats as wiki link")
do
  local dir = api.get_memos_dir()
  assert((dir == "/tmp/test-memos"), "get_memos_dir: delegates to config")
end
return print("api_test.lua: All tests passed")
