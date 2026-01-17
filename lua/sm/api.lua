local M = {}
M.get_memos = function()
  local memo = require("sm.memo")
  local tags_mod = require("sm.tags")
  local files = memo.list()
  local entries = {}
  for _, filepath in ipairs(files) do
    local info = memo["get-memo-info"](filepath)
    local tags = tags_mod["get-memo-tags"](filepath)
    local tags_str
    if (#tags > 0) then
      tags_str = (" [" .. table.concat(tags, ", ") .. "]")
    else
      tags_str = ""
    end
    local display = (info.date .. " | " .. info.title .. tags_str)
    local ordinal = (info.date .. " " .. info.title .. " " .. table.concat(tags, " "))
    table.insert(entries, {value = filepath, text = display, ordinal = ordinal, info = info, tags = tags})
  end
  return entries
end
M.get_tags = function()
  local tags_mod = require("sm.tags")
  local tags_with_counts = tags_mod["get-tags-with-counts"]()
  local entries = {}
  for _, item in ipairs(tags_with_counts) do
    table.insert(entries, {value = item.tag, text = string.format("%-20s (%d memos)", item.tag, item.count), ordinal = item.tag, count = item.count})
  end
  return entries
end
M.get_memos_by_tag = function(tag)
  local memo = require("sm.memo")
  local tags_mod = require("sm.tags")
  local files = tags_mod["get-memos-by-tag"](tag)
  local entries = {}
  for _, filepath in ipairs(files) do
    local info = memo["get-memo-info"](filepath)
    local display = (info.date .. " | " .. info.title)
    local ordinal = (info.date .. " " .. info.title)
    table.insert(entries, {value = filepath, text = display, ordinal = ordinal, info = info})
  end
  return entries
end
M.get_memos_for_link = function()
  local memo = require("sm.memo")
  local files = memo.list()
  local entries = {}
  for _, filepath in ipairs(files) do
    local info = memo["get-memo-info"](filepath)
    local filename = vim.fn.fnamemodify(filepath, ":t:r")
    local display = (info.date .. " | " .. info.title)
    local ordinal = (info.date .. " " .. info.title)
    table.insert(entries, {value = filename, text = display, ordinal = ordinal, filepath = filepath})
  end
  return entries
end
M.open_memo = function(filepath)
  local memo = require("sm.memo")
  return memo.open(filepath)
end
M.insert_link = function(filename)
  local link = ("[[" .. filename .. "]]")
  return vim.api.nvim_put({link}, "c", true, true)
end
M.get_memos_dir = function()
  local config = require("sm.config")
  return config["get-memos-dir"]()
end
return M
