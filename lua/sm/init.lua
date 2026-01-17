local M = {}
local function has_telescope_3f()
  local ok, _ = pcall(require, "telescope")
  return ok
end
M.setup = function(_3fopts)
  local config = require("sm.config")
  local cmd = require("sm.cmd")
  config.setup(_3fopts)
  cmd.setup()
  return M["setup-autocmds"]()
end
M["setup-autocmds"] = function()
  local group = vim.api.nvim_create_augroup("sm_nvim", {clear = true})
  local config = require("sm.config")
  local function _1_()
    local links = require("sm.links")
    return links["setup-buffer-mappings"]()
  end
  return vim.api.nvim_create_autocmd({"BufEnter"}, {group = group, pattern = (config["get-memos-dir"]() .. "/*.md"), callback = _1_})
end
M.create = function(_3ftitle)
  local memo = require("sm.memo")
  return memo.create(_3ftitle)
end
M["open-last"] = function()
  local memo = require("sm.memo")
  return memo["open-last"]()
end
M.list = function()
  if has_telescope_3f() then
    local telescope = require("sm.telescope")
    return telescope["memo-picker"]()
  else
    return vim.notify("sm.nvim: Telescope not found. Use require('sm.api').get_memos() with your preferred picker.", vim.log.levels.WARN)
  end
end
M.grep = function()
  if has_telescope_3f() then
    local telescope = require("sm.telescope")
    return telescope["memo-grep"]()
  else
    local config = require("sm.config")
    return vim.notify(("sm.nvim: Telescope not found. Use grep in: " .. config["get-memos-dir"]()), vim.log.levels.WARN)
  end
end
M.tags = function()
  if has_telescope_3f() then
    local telescope = require("sm.telescope")
    return telescope["tag-picker"]()
  else
    return vim.notify("sm.nvim: Telescope not found. Use require('sm.api').get_tags() with your preferred picker.", vim.log.levels.WARN)
  end
end
M["search-by-tag"] = function(tag)
  if has_telescope_3f() then
    local telescope = require("sm.telescope")
    return telescope["memos-by-tag-picker"](tag)
  else
    return vim.notify("sm.nvim: Telescope not found. Use require('sm.api').get_memos_by_tag(tag) with your preferred picker.", vim.log.levels.WARN)
  end
end
M["follow-link"] = function()
  local links = require("sm.links")
  return links["follow-link"]()
end
M["insert-link"] = function()
  if has_telescope_3f() then
    local links = require("sm.links")
    return links["insert-link"]()
  else
    return vim.notify("sm.nvim: Telescope not found. Use require('sm.api').get_memos_for_link() with your preferred picker.", vim.log.levels.WARN)
  end
end
M["list-all-tags"] = function()
  local tags = require("sm.tags")
  return tags["list-all-tags"]()
end
M["add-tag"] = function(_3ftag)
  local tags = require("sm.tags")
  local filepath = vim.api.nvim_buf_get_name(0)
  if _3ftag then
    return tags["add-tag-to-memo"](filepath, _3ftag)
  else
    local function _7_(input)
      if (input and (#input > 0)) then
        tags["add-tag-to-memo"](filepath, input)
        return vim.notify(("Added tag: " .. input), vim.log.levels.INFO)
      else
        return nil
      end
    end
    return vim.ui.input({prompt = "Tag to add: "}, _7_)
  end
end
return M
