local M = {}
local defaults = {["memos-dir"] = nil, ["state-file"] = nil, ["date-format"] = "%Y%m%d_%H%M%S", template = {"---", "tags: []", "created: %date%", "---", "", "# %title%", ""}, window = {width = 80, height = 30, border = "rounded", style = "minimal"}}
local config = nil
M["get-base-dir"] = function()
  return (vim.fn.stdpath("cache") .. "/sm")
end
M["get-memos-dir"] = function()
  local cfg = M.get()
  if cfg["memos-dir"] then
    return cfg["memos-dir"]
  else
    return (M["get-base-dir"]() .. "/memos")
  end
end
M["get-state-file"] = function()
  local cfg = M.get()
  if cfg["state-file"] then
    return cfg["state-file"]
  else
    return (M["get-base-dir"]() .. "/state.json")
  end
end
M.setup = function(_3fopts)
  config = vim.tbl_deep_extend("force", defaults, (_3fopts or {}))
  return config
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
  return nil
end
M["_reset"] = M.reset
return M
