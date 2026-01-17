local M = {}
local config = require("sm.config")
local state = require("sm.state")
local function ensure_memos_dir()
  local dir = config["get-memos-dir"]()
  if (vim.fn.isdirectory(dir) == 0) then
    vim.fn.mkdir(dir, "p")
  else
  end
  return dir
end
local function sanitize_title(title)
  return title:lower():gsub("[^%w%-%_]+", "-"):gsub("^%-+", ""):gsub("%-+$", ""):gsub("%-%-+", "-")
end
M["generate-filename"] = function(title)
  local cfg = config.get()
  local date = os.date(cfg["date-format"])
  local safe_title = sanitize_title(title)
  return (date .. "_" .. safe_title .. ".md")
end
M["generate-template"] = function(title)
  local cfg = config.get()
  local date_str = os.date("%Y-%m-%dT%H:%M:%S")
  local lines = {}
  for _, line in ipairs(cfg.template) do
    local processed = line:gsub("%%date%%", date_str):gsub("%%title%%", title)
    table.insert(lines, processed)
  end
  return table.concat(lines, "\n")
end
M["get-filepath"] = function(filename)
  return (config["get-memos-dir"]() .. "/" .. filename)
end
M["open-in-window"] = function(filepath, _3fopts)
  local cfg = config.get()
  local opts = (_3fopts or {})
  local width = (opts.width or cfg.window.width)
  local height = (opts.height or cfg.window.height)
  local buf = vim.fn.bufadd(filepath)
  vim.fn.bufload(buf)
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  vim.api.nvim_open_win(buf, true, {relative = "editor", style = cfg.window.style, border = cfg.window.border, row = 3, col = (vim.o.columns - width - 2), height = height, width = width})
  vim.wo["wrap"] = true
  local function _2_()
    local function _3_()
      return require("copilot.command").attach({force = true})
    end
    return pcall(_3_)
  end
  vim.defer_fn(_2_, 150)
  return buf
end
M.create = function(_3ftitle)
  if _3ftitle then
    local _ = ensure_memos_dir()
    local filename = M["generate-filename"](_3ftitle)
    local filepath = M["get-filepath"](filename)
    local content = M["generate-template"](_3ftitle)
    do
      local file, err = io.open(filepath, "w")
      if file then
        file:write(content)
        file:close()
      else
      end
    end
    M["open-in-window"](filepath)
    state["set-last-edited"](filename)
    state["add-recent"](filename)
    return filepath
  else
    local function _5_(input)
      if (input and (#input > 0)) then
        return M.create(input)
      else
        return nil
      end
    end
    return vim.ui.input({prompt = "Memo title: "}, _5_)
  end
end
M.open = function(filepath)
  local filename = vim.fn.fnamemodify(filepath, ":t")
  M["open-in-window"](filepath)
  state["set-last-edited"](filename)
  return state["add-recent"](filename)
end
M["open-last"] = function()
  local last_path = state["get-last-edited"]()
  if (last_path and (vim.fn.filereadable(last_path) == 1)) then
    return M.open(last_path)
  else
    vim.notify("No recent memo found. Creating new one...", vim.log.levels.INFO)
    return M.create()
  end
end
M.list = function()
  ensure_memos_dir()
  local dir = config["get-memos-dir"]()
  local files = vim.fn.glob((dir .. "/*.md"), false, true)
  local function _9_(a, b)
    return (a > b)
  end
  table.sort(files, _9_)
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
M["get-memo-info"] = function(filepath)
  local filename = vim.fn.fnamemodify(filepath, ":t")
  local date_part = filename:match("^(%d+_%d+)_")
  local title_part = (filename:match("^%d+_%d+_(.+)%.md$") or "untitled")
  return {filepath = filepath, filename = filename, date = date_part, title = title_part:gsub("-", " ")}
end
local method_name = ...
if (method_name == nil) then
  assert((sanitize_title("Hello World!") == "hello-world"), "sanitize: spaces and punctuation")
  assert((sanitize_title("  Test  ") == "test"), "sanitize: trim whitespace")
  assert((sanitize_title("My--Title") == "my-title"), "sanitize: collapse dashes")
  assert((sanitize_title("CamelCase") == "camelcase"), "sanitize: lowercase")
  do
    local filename = M["generate-filename"]("test")
    assert(filename:match("^%d+_%d+_test%.md$"), "filename: format YYYYMMDD_HHMMSS_title.md")
  end
  do
    local content = M["generate-template"]("Test Title")
    assert(content:match("^%-%-%-"), "template: starts with frontmatter")
    assert(content:match("tags: %[%]"), "template: has empty tags")
    assert(content:match("# Test Title"), "template: has title heading")
  end
  do
    local info = M["get-memo-info"]("/path/to/20260117_143052_my-memo.md")
    assert((info.filename == "20260117_143052_my-memo.md"), "info: filename")
    assert((info.date == "20260117_143052"), "info: date")
    assert((info.title == "my memo"), "info: title with spaces")
  end
  print("memo.fnl: All tests passed")
else
end
return M
