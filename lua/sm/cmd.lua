local M = {}
M.setup = function()
  local function _1_()
    return require("sm").open_last()
  end
  vim.api.nvim_create_user_command("SmOpen", _1_, {desc = "Open last edited memo"})
  local function _2_(opts)
    local sm = require("sm")
    local title
    if (opts.args and (#opts.args > 0)) then
      title = opts.args
    else
      title = nil
    end
    return sm.create(title)
  end
  vim.api.nvim_create_user_command("SmNew", _2_, {nargs = "?", desc = "Create new memo"})
  local function _4_(opts)
    local tag
    if (opts.args and (#opts.args > 0)) then
      tag = opts.args
    else
      tag = nil
    end
    return require("sm").add_tag(tag)
  end
  local function _6_()
    return require("sm").list_all_tags()
  end
  vim.api.nvim_create_user_command("SmAddTag", _4_, {nargs = "?", complete = _6_, desc = "Add tag to current memo"})
  local function _7_()
    return require("sm").follow_link()
  end
  vim.api.nvim_create_user_command("SmFollowLink", _7_, {desc = "Follow wiki link under cursor"})
  local function _8_()
    local meta = require("sm.meta")
    return meta.show_in_float()
  end
  return vim.api.nvim_create_user_command("SmMetaMemo", _8_, {desc = "Show self-aware memo statistics (joke)"})
end
return M
