local M = {}
M.setup = function()
  local function _1_()
    return require("sm")["open-last"]()
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
    return require("sm")["add-tag"](tag)
  end
  local function _6_()
    return require("sm")["list-all-tags"]()
  end
  vim.api.nvim_create_user_command("SmAddTag", _4_, {nargs = "?", complete = _6_, desc = "Add tag to current memo"})
  local function _7_()
    return require("sm")["follow-link"]()
  end
  return vim.api.nvim_create_user_command("SmFollowLink", _7_, {desc = "Follow wiki link under cursor"})
end
return M
