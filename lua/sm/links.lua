local M = {}
local config = require("sm.config")
M["parse-link"] = function(text)
  return text:match("%[%[([^%]]+)%]%]")
end
M["get-link-under-cursor"] = function()
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
M["find-memo-by-partial"] = function(name)
  local memo = require("sm.memo")
  local files = memo.list()
  local dir = config["get-memos-dir"]()
  local name_lower = name:lower()
  local result = nil
  for _, filepath in ipairs(files) do
    if result then break end
    local filename = vim.fn.fnamemodify(filepath, ":t:r")
    local filename_lower = filename:lower()
    if ((filename_lower == name_lower) or filename_lower:find(name_lower, 1, true)) then
      result = filepath
    else
    end
  end
  return result
end
M["follow-link"] = function()
  local link_text = M["get-link-under-cursor"]()
  if link_text then
    local target = M["find-memo-by-partial"](link_text)
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
M["create-link-from-selection"] = function()
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
M["insert-link"] = function()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local memo = require("sm.memo")
  local files = memo.list()
  local entries = {}
  for _, filepath in ipairs(files) do
    local info = memo["get-memo-info"](filepath)
    local filename = vim.fn.fnamemodify(filepath, ":t:r")
    table.insert(entries, {value = filename, display = (info.date .. " | " .. info.title), ordinal = (info.date .. " " .. info.title)})
  end
  local function _8_(entry)
    return entry
  end
  local function _9_(prompt_bufnr, map)
    local function _10_()
      actions.close(prompt_bufnr)
      local selection = action_state.get_selected_entry()
      local link = ("[[" .. selection.value .. "]]")
      return vim.api.nvim_put({link}, "c", true, true)
    end
    actions.select_default:replace(_10_)
    return true
  end
  return pickers.new({}, {prompt_title = "Insert Link", finder = finders.new_table({results = entries, entry_maker = _8_}), sorter = conf.generic_sorter({}), attach_mappings = _9_}):find()
end
M["setup-buffer-mappings"] = function()
  local buf = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(buf)
  local memos_dir = config["get-memos-dir"]()
  if vim.startswith(filepath, memos_dir) then
    local function _11_()
      return M["follow-link"]()
    end
    return vim.keymap.set("n", "gf", _11_, {buffer = buf, desc = "Follow wiki link"})
  else
    return nil
  end
end
local method_name = ...
if (method_name == nil) then
  assert((M["parse-link"]("[[memo-name]]") == "memo-name"), "parse: simple link")
  assert((M["parse-link"]("[[20260117_test]]") == "20260117_test"), "parse: timestamp link")
  assert((M["parse-link"]("text [[link]] more") == "link"), "parse: link in text")
  assert((M["parse-link"]("[[my memo title]]") == "my memo title"), "parse: link with spaces")
  assert((M["parse-link"]("no link here") == nil), "parse: no link")
  assert((M["parse-link"]("[single bracket]") == nil), "parse: single brackets")
  assert((M["parse-link"]("[[]]") == nil), "parse: empty link")
  assert((M["parse-link"]("[[unclosed") == nil), "parse: unclosed link")
  assert((M["parse-link"]("[[first]] and [[second]]") == "first"), "parse: multiple links")
  print("links.fnl: All tests passed")
else
end
return M
