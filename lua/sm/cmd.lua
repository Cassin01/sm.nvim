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
  local function _4_()
    return require("sm").list()
  end
  vim.api.nvim_create_user_command("SmList", _4_, {desc = "List all memos"})
  local function _5_()
    return require("sm").grep()
  end
  vim.api.nvim_create_user_command("SmGrep", _5_, {desc = "Search memo contents"})
  local function _6_()
    return require("sm").tags()
  end
  vim.api.nvim_create_user_command("SmTags", _6_, {desc = "Browse memos by tag"})
  local function _7_(opts)
    return require("sm")["search-by-tag"](opts.args)
  end
  local function _8_()
    return require("sm")["list-all-tags"]()
  end
  vim.api.nvim_create_user_command("SmTagSearch", _7_, {nargs = 1, complete = _8_, desc = "Search memos by tag"})
  local function _9_(opts)
    local tag
    if (opts.args and (#opts.args > 0)) then
      tag = opts.args
    else
      tag = nil
    end
    return require("sm")["add-tag"](tag)
  end
  local function _11_()
    return require("sm")["list-all-tags"]()
  end
  vim.api.nvim_create_user_command("SmAddTag", _9_, {nargs = "?", complete = _11_, desc = "Add tag to current memo"})
  local function _12_()
    return require("sm")["follow-link"]()
  end
  vim.api.nvim_create_user_command("SmFollowLink", _12_, {desc = "Follow wiki link under cursor"})
  local function _13_()
    return require("sm")["insert-link"]()
  end
  return vim.api.nvim_create_user_command("SmInsertLink", _13_, {desc = "Insert wiki link from picker"})
end
return M
