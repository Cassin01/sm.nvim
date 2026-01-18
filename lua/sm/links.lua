local M = {}
local config = require("sm.config")
M.parse_link = function(text)
  return text:match("%[%[([^%]]+)%]%]")
end
M.get_link_under_cursor = function()
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".")
  local before = line:sub(1, col)
  local after = line:sub(col)
  local start_pos = before:match(".*()%[%[")
  if start_pos then
    local full_from_start = line:sub(start_pos)
    local link = full_from_start:match("%[%[([^%]]+)%]%]")
    return link
  else
    return nil
  end
end
M.find_memo_by_partial = function(name)
  local memo = require("sm.memo")
  local files = memo.list()
  local dir = config.get_memos_dir()
  local name_lower = name:lower()
  local result = nil
  for _, filepath in ipairs(files) do
    if result then break end
    local filename = vim.fn.fnamemodify(filepath, ":t:r")
    local filename_lower = filename:lower()
    if (filename_lower == name_lower) then
      result = filepath
    else
    end
  end
  if not result then
    for _, filepath in ipairs(files) do
      if result then break end
      local filename = vim.fn.fnamemodify(filepath, ":t:r")
      local filename_lower = filename:lower()
      if filename_lower:find(name_lower, 1, true) then
        result = filepath
      else
      end
    end
  end
  return result
end
M.follow_link = function()
  local link_text = M.get_link_under_cursor()
  if link_text then
    local target = M.find_memo_by_partial(link_text)
    if target then
      local memo = require("sm.memo")
      return memo.open(target)
    else
      vim.notify(("Memo not found: " .. link_text .. ". Create new?"), vim.log.levels.INFO)
      local function _3_(choice)
        if (choice == "Yes") then
          local memo = require("sm.memo")
          return memo.create(link_text)
        else
          return nil
        end
      end
      return vim.ui.select({"Yes", "No"}, {prompt = "Create new memo?"}, _3_)
    end
  else
    return vim.notify("No wiki link under cursor", vim.log.levels.WARN)
  end
end
M.create_link_from_selection = function()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local lines = vim.api.nvim_buf_get_text(0, (start_pos[2] - 1), (start_pos[3] - 1), (end_pos[2] - 1), end_pos[3], {})
  if (#lines > 0) then
    local text = table.concat(lines, " ")
    local link = ("[[" .. text .. "]]")
    return vim.api.nvim_buf_set_text(0, (start_pos[2] - 1), (start_pos[3] - 1), (end_pos[2] - 1), end_pos[3], {link})
  else
    return nil
  end
end
M.setup_buffer_mappings = function()
  local buf = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(buf)
  local memos_dir = config.get_memos_dir()
  if vim.startswith(filepath, memos_dir) then
    local function _8_()
      return M.follow_link()
    end
    return vim.keymap.set("n", "gf", _8_, {buffer = buf, desc = "Follow wiki link"})
  else
    return nil
  end
end
return M
