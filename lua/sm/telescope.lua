local M = {}
local config = require("sm.config")
M["memo-picker"] = function()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local previewers = require("telescope.previewers")
  local memo = require("sm.memo")
  local tags_mod = require("sm.tags")
  local files = memo.list()
  local entries = {}
  for _, filepath in ipairs(files) do
    local info = memo["get-memo-info"](filepath)
    local tags = tags_mod["get-memo-tags"](filepath)
    local tags_str
    if (#tags > 0) then
      tags_str = (" [" .. table.concat(tags, ", ") .. "]")
    else
      tags_str = ""
    end
    table.insert(entries, {value = filepath, display = (info.date .. " | " .. info.title .. tags_str), ordinal = (info.date .. " " .. info.title .. " " .. table.concat(tags, " "))})
  end
  local function _2_(entry)
    return entry
  end
  local function _3_(self, entry, bufnr)
    return conf.buffer_previewer_maker(entry.value, bufnr, {})
  end
  local function _4_(prompt_bufnr, map)
    local function _5_()
      actions.close(prompt_bufnr)
      local selection = action_state.get_selected_entry()
      return memo.open(selection.value)
    end
    actions.select_default:replace(_5_)
    return true
  end
  return pickers.new({}, {prompt_title = "Memos", finder = finders.new_table({results = entries, entry_maker = _2_}), sorter = conf.generic_sorter({}), previewer = previewers.new_buffer_previewer({title = "Memo Preview", define_preview = _3_}), attach_mappings = _4_}):find()
end
M["memo-grep"] = function()
  local builtin = require("telescope.builtin")
  return builtin.live_grep({cwd = config["get-memos-dir"](), prompt_title = "Grep Memos", glob_pattern = "*.md"})
end
M["tag-picker"] = function()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local tags_mod = require("sm.tags")
  local tags_with_counts = tags_mod["get-tags-with-counts"]()
  local function _6_(entry)
    return {value = entry.tag, display = string.format("%-20s (%d memos)", entry.tag, entry.count), ordinal = entry.tag}
  end
  local function _7_(prompt_bufnr, map)
    local function _8_()
      actions.close(prompt_bufnr)
      local selection = action_state.get_selected_entry()
      return M["memos-by-tag-picker"](selection.value)
    end
    actions.select_default:replace(_8_)
    return true
  end
  return pickers.new({}, {prompt_title = "Tags", finder = finders.new_table({results = tags_with_counts, entry_maker = _6_}), sorter = conf.generic_sorter({}), attach_mappings = _7_}):find()
end
M["memos-by-tag-picker"] = function(tag)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local previewers = require("telescope.previewers")
  local memo = require("sm.memo")
  local tags_mod = require("sm.tags")
  local files = tags_mod["get-memos-by-tag"](tag)
  local entries = {}
  for _, filepath in ipairs(files) do
    local info = memo["get-memo-info"](filepath)
    table.insert(entries, {value = filepath, display = (info.date .. " | " .. info.title), ordinal = (info.date .. " " .. info.title)})
  end
  local function _9_(entry)
    return entry
  end
  local function _10_(self, entry, bufnr)
    return conf.buffer_previewer_maker(entry.value, bufnr, {})
  end
  local function _11_(prompt_bufnr, map)
    local function _12_()
      actions.close(prompt_bufnr)
      local selection = action_state.get_selected_entry()
      return memo.open(selection.value)
    end
    actions.select_default:replace(_12_)
    return true
  end
  return pickers.new({}, {prompt_title = ("Memos tagged: " .. tag), finder = finders.new_table({results = entries, entry_maker = _9_}), sorter = conf.generic_sorter({}), previewer = previewers.new_buffer_previewer({title = "Memo Preview", define_preview = _10_}), attach_mappings = _11_}):find()
end
return M
