local M = {}
M.setup = function(_3fopts)
  local config = require("sm.config")
  local cmd = require("sm.cmd")
  config.setup(_3fopts)
  cmd.setup()
  return M.setup_autocmds()
end
M.setup_autocmds = function()
  local group = vim.api.nvim_create_augroup("sm_nvim", {clear = true})
  local config = require("sm.config")
  local function _1_()
    local links = require("sm.links")
    return links.setup_buffer_mappings()
  end
  return vim.api.nvim_create_autocmd({"BufEnter"}, {group = group, pattern = (config.get_memos_dir() .. "/*.md"), callback = _1_})
end
M.create = function(_3ftitle)
  local memo = require("sm.memo")
  return memo.create(_3ftitle)
end
M.open_last = function()
  local memo = require("sm.memo")
  return memo.open_last()
end
M.follow_link = function()
  local links = require("sm.links")
  return links.follow_link()
end
M.list_all_tags = function()
  local tags = require("sm.tags")
  return tags.list_all_tags()
end
M.add_tag = function(_3ftag)
  local tags = require("sm.tags")
  local filepath = vim.api.nvim_buf_get_name(0)
  if _3ftag then
    return tags.add_tag_to_memo(filepath, _3ftag)
  else
    local function _2_(input)
      if (input and (#input > 0)) then
        tags.add_tag_to_memo(filepath, input)
        return vim.notify(("Added tag: " .. input), vim.log.levels.INFO)
      else
        return nil
      end
    end
    return vim.ui.input({prompt = "Tag to add: "}, _2_)
  end
end
return M
