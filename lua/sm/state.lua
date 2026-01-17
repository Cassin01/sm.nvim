local M = {}
local config = require("sm.config")
local function ensure_dir(path)
  if (vim.fn.isdirectory(path) == 0) then
    return vim.fn.mkdir(path, "p")
  else
    return nil
  end
end
local function read_json(filepath)
  local file, err = io.open(filepath, "r")
  if file then
    local content = file:read("*all")
    file:close()
    if (content and (#content > 0)) then
      return vim.fn.json_decode(content)
    else
      return {}
    end
  else
    return {}
  end
end
local function write_json(filepath, data)
  ensure_dir(vim.fn.fnamemodify(filepath, ":h"))
  local file, err = io.open(filepath, "w")
  if file then
    file:write(vim.fn.json_encode(data))
    file:close()
    return true
  else
    return nil
  end
end
M.load = function()
  return read_json(config["get-state-file"]())
end
M.save = function(state)
  return write_json(config["get-state-file"](), state)
end
M["get-last-edited"] = function()
  local state = M.load()
  if state.last_edited then
    return (config["get-memos-dir"]() .. "/" .. state.last_edited)
  else
    return nil
  end
end
M["set-last-edited"] = function(filename)
  local state = M.load()
  state["last_edited"] = filename
  state["last_accessed"] = os.time()
  return M.save(state)
end
M["get-recent"] = function(_3flimit)
  local state = M.load()
  local limit = (_3flimit or 10)
  return (state.recent or {})
end
M["add-recent"] = function(filename)
  local state = M.load()
  local recent = (state.recent or {})
  local filtered
  local function _6_(_241)
    return (_241 ~= filename)
  end
  filtered = vim.tbl_filter(_6_, recent)
  table.insert(filtered, 1, filename)
  while (#filtered > 20) do
    table.remove(filtered)
  end
  state["recent"] = filtered
  return M.save(state)
end
M["_read-json"] = read_json
M["_write-json"] = write_json
return M
