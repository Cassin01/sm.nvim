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
M.generate_template = function(title, _3finitial_tags)
  local cfg = config.get()
  local date_str = os.date("%Y-%m-%dT%H:%M:%S")
  local tags = (_3finitial_tags or {})
  local tags_str = table.concat(tags, ", ")
  local lines = {}
  for _, line in ipairs(cfg.template) do
    local processed = line:gsub("%%date%%", date_str):gsub("%%title%%", title):gsub("%%tags%%", tags_str):gsub("tags: %[%]", ("tags: [" .. tags_str .. "]"), 1)
    table.insert(lines, processed)
  end
  return table.concat(lines, "\n")
end
M.get_filepath = function(filename)
  return (config.get_memos_dir() .. "/" .. filename)
end
local function get_initial_tags()
  local cfg = config.get()
  local tags = {}
  if cfg.auto_tag_git_repo then
    local git = require("sm.git")
    local repo_tag = git.get_repo_tag()
    if repo_tag then
      table.insert(tags, repo_tag)
    else
    end
  else
  end
  return tags
end
local function try_attach_copilot(attempts)
  local cfg = config.get()
  if cfg.copilot_integration then
    local copilot_ok, copilot = pcall(require, "copilot.command")
    if copilot_ok then
      local max_attempts = 3
      local delay = (attempts * 100)
      local function _4_()
        local ok, err
        local function _5_()
          return copilot.attach({force = true})
        end
        ok, err = pcall(_5_)
        if (not ok and (attempts < max_attempts)) then
          return try_attach_copilot((attempts + 1))
        else
          return nil
        end
      end
      return vim.defer_fn(_4_, delay)
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
  vim.api.nvim_open_win(buf, true, {relative = "editor", style = cfg.window.style, border = cfg.window.border, row = 3, col = (vim.o.columns - width - 2), height = height, width = width})
  vim.wo["wrap"] = true
  try_attach_copilot(1)
  return buf
end
M.create = function(_3ftitle)
  if _3ftitle then
    local _ = ensure_memos_dir()
    local filename = M.generate_filename(_3ftitle)
    local filepath = M.get_filepath(filename)
    local initial_tags = get_initial_tags()
    local content = M.generate_template(_3ftitle, initial_tags)
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
    local function _10_(input)
      if (input and (#input > 0)) then
        return M.create(input)
      else
        return nil
      end
    end
    return vim.ui.input({prompt = "Memo title: "}, _10_)
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
  local function _14_(a, b)
    return (a > b)
  end
  table.sort(files, _14_)
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
