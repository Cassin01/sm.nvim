local M = {}
local config = require("sm.config")
local state = require("sm.state")
local function ensure_memos_dir()
  local dir = config.get_memos_dir()
  if (vim.fn.isdirectory(dir) == 0) then
    vim.fn.mkdir(dir, "p")
  else
  end
  return dir
end
local function sanitize_title(title)
  return title:lower():gsub("[^%w%-%_]+", "-"):gsub("^%-+", ""):gsub("%-+$", ""):gsub("%-%-+", "-")
end
M.generate_filename = function(title)
  local cfg = config.get()
  local date = os.date(cfg.date_format)
  local safe_title = sanitize_title(title)
  return (date .. "_" .. safe_title .. ".md")
end
M.generate_template = function(title)
  local cfg = config.get()
  local date_str = os.date("%Y-%m-%dT%H:%M:%S")
  local lines = {}
  for _, line in ipairs(cfg.template) do
    local processed = line:gsub("%%date%%", date_str):gsub("%%title%%", title)
    table.insert(lines, processed)
  end
  return table.concat(lines, "\n")
end
M.get_filepath = function(filename)
  return (config.get_memos_dir() .. "/" .. filename)
end
local function create_centered_input(prompt, callback)
  local width = 50
  local height = 1
  local row = math.max(0, math.floor(((vim.o.lines - height) / 2)))
  local col = math.max(0, math.floor(((vim.o.columns - width) / 2)))
  local buf = vim.api.nvim_create_buf(false, true)
  local ok, win = pcall(vim.api.nvim_open_win, buf, true, {relative = "editor", width = width, height = height, row = row, col = col, style = "minimal", border = "rounded", title = (" " .. prompt .. " "), title_pos = "center"})
  if not ok then
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, {force = true})
    else
    end
    return vim.notify("Failed to create memo input window", vim.log.levels.ERROR)
  else
    local function close_input()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      else
      end
      if vim.api.nvim_buf_is_valid(buf) then
        return vim.api.nvim_buf_delete(buf, {force = true})
      else
        return nil
      end
    end
    local function submit()
      local lines = vim.api.nvim_buf_get_lines(buf, 0, 1, false)
      local text = (lines[1] or "")
      close_input()
      if (#text > 0) then
        return callback(text)
      else
        return nil
      end
    end
    vim.keymap.set("i", "<CR>", submit, {buffer = buf, noremap = true})
    vim.keymap.set("n", "<CR>", submit, {buffer = buf, noremap = true})
    vim.keymap.set("i", "<Esc>", close_input, {buffer = buf, noremap = true})
    vim.keymap.set("n", "<Esc>", close_input, {buffer = buf, noremap = true})
    vim.keymap.set("n", "q", close_input, {buffer = buf, noremap = true})
    return vim.cmd("startinsert")
  end
end
local function try_attach_copilot(attempts)
  local cfg = config.get()
  if cfg.copilot_integration then
    local copilot_ok, copilot = pcall(require, "copilot.command")
    if copilot_ok then
      local max_attempts = 3
      local delay = (attempts * 100)
      local function _7_()
        local ok, err
        local function _8_()
          return copilot.attach({force = true})
        end
        ok, err = pcall(_8_)
        if (not ok and (attempts < max_attempts)) then
          return try_attach_copilot((attempts + 1))
        else
          return nil
        end
      end
      return vim.defer_fn(_7_, delay)
    else
      return nil
    end
  else
    return nil
  end
end
M.open_in_window = function(filepath, _3fopts)
  local cfg = config.get()
  local opts = (_3fopts or {})
  local width = (opts.width or cfg.window.width)
  local height = (opts.height or cfg.window.height)
  local buf = vim.fn.bufadd(filepath)
  vim.fn.bufload(buf)
  vim.bo[buf]["filetype"] = "markdown"
  vim.api.nvim_open_win(buf, true, {relative = "editor", style = cfg.window.style, border = cfg.window.border, row = math.max(0, (vim.o.lines - height - 4)), col = 2, height = height, width = width})
  vim.wo["wrap"] = true
  try_attach_copilot(1)
  return buf
end
M.create = function(_3ftitle)
  if _3ftitle then
    local _ = ensure_memos_dir()
    local filename = M.generate_filename(_3ftitle)
    local filepath = M.get_filepath(filename)
    local content = M.generate_template(_3ftitle)
    do
      local file, err = io.open(filepath, "w")
      if file then
        file:write(content)
        file:close()
      else
        vim.notify(("Failed to create memo: " .. (err or "unknown error")), vim.log.levels.ERROR)
      end
    end
    M.open_in_window(filepath)
    state.set_last_edited(filename)
    state.add_recent(filename)
    return filepath
  else
    return create_centered_input("Memo title:", M.create)
  end
end
M.open = function(filepath)
  local filename = vim.fn.fnamemodify(filepath, ":t")
  M.open_in_window(filepath)
  state.set_last_edited(filename)
  return state.add_recent(filename)
end
M.open_last = function()
  local last_path = state.get_last_edited()
  if (last_path and (vim.fn.filereadable(last_path) == 1)) then
    return M.open(last_path)
  else
    vim.notify("No recent memo found. Creating new one...", vim.log.levels.INFO)
    return M.create()
  end
end
M.list = function()
  ensure_memos_dir()
  local dir = config.get_memos_dir()
  local files = vim.fn.glob((dir .. "/*.md"), false, true)
  local function _15_(a, b)
    return (a > b)
  end
  table.sort(files, _15_)
  return files
end
M.delete = function(filepath)
  if (vim.fn.filereadable(filepath) == 1) then
    os.remove(filepath)
    return true
  else
    return nil
  end
end
M.get_memo_info = function(filepath)
  local filename = vim.fn.fnamemodify(filepath, ":t")
  local date_part = filename:match("^(%d+_%d+)_")
  local title_part = (filename:match("^%d+_%d+_(.+)%.md$") or "untitled")
  return {filepath = filepath, filename = filename, date = date_part, title = title_part:gsub("-", " ")}
end
M["_sanitize_title"] = sanitize_title
return M
