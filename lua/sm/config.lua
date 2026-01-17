local M = {}
local defaults = {memos_dir = nil, state_file = nil, date_format = "%Y%m%d_%H%M%S", template = {"---", "tags: []", "created: %date%", "---", "", "# %title%", ""}, window = {width = 80, height = 30, border = "rounded", style = "minimal"}, auto_tag_git_repo = false, copilot_integration = false}
local config = nil
local setup_called = false
M.get_base_dir = function()
  return (vim.fn.stdpath("cache") .. "/sm")
end
M.get_memos_dir = function()
  local cfg = M.get()
  if cfg.memos_dir then
    return cfg.memos_dir
  else
    return (M.get_base_dir() .. "/memos")
  end
end
M.get_state_file = function()
  local cfg = M.get()
  if cfg.state_file then
    return cfg.state_file
  else
    return (M.get_base_dir() .. "/state.json")
  end
end
M.setup = function(_3fopts)
  if setup_called then
    vim.notify("sm.nvim: setup() called multiple times, ignoring subsequent call", vim.log.levels.WARN)
    return config
  else
    config = vim.tbl_deep_extend("force", defaults, (_3fopts or {}))
    setup_called = true
    return config
  end
end
M.get = function()
  if (config == nil) then
    M.setup({})
  else
  end
  return vim.deepcopy(config)
end
M.reset = function()
  config = nil
  setup_called = false
  return nil
end
M["_reset"] = M.reset
return M
