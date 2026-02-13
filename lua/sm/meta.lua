local M = {}
M.get_statistics = function()
  local memo = require("sm.memo")
  local tags = require("sm.tags")
  local state = require("sm.state")
  local files = memo.list()
  local all_tags = tags.list_all_tags()
  local top_tags = tags.get_tags_with_counts()
  local recent = state.get_recent()
  local last_edited = state.get_last_edited()
  return {total_memos = #files, total_tags = #all_tags, top_tags = top_tags, recent_count = #recent, last_edited = last_edited}
end
M.get_behavior_analysis = function(stats)
  local observations = {}
  if (stats.total_memos < 5) then
    table.insert(observations, "A beginner. The void welcomes you.")
  elseif (stats.total_memos < 20) then
    table.insert(observations, "A casual note-taker. The abyss is patient.")
  elseif (stats.total_memos < 50) then
    table.insert(observations, "A developing habit. Most will never be read again.")
  elseif (stats.total_memos < 100) then
    table.insert(observations, "A prolific scribe. Your future self weeps at the backlog.")
  else
    table.insert(observations, "A hoarder of thoughts. You have become the archive.")
  end
  if (#stats.top_tags > 0) then
    local top_tag = stats.top_tags[1]
    if (top_tag.tag == "todo") then
      table.insert(observations, "Your most used tag is 'todo'. Interesting choice for things you'll never do.")
    elseif (top_tag.tag == "urgent") then
      table.insert(observations, ("'Urgent' used " .. top_tag.count .. " times. Nothing is urgent if everything is urgent."))
    elseif (top_tag.tag == "important") then
      table.insert(observations, ("'Important' tagged " .. top_tag.count .. " times. The truly important needs no label."))
    elseif (top_tag.tag == "work") then
      table.insert(observations, ("'Work' tagged " .. top_tag.count .. " times. Are you working or documenting avoidance?"))
    elseif (top_tag.tag == "ideas") then
      table.insert(observations, ("Ideas: " .. top_tag.count .. ". Implementations: unknown. The ratio is concerning."))
    else
      table.insert(observations, ("'" .. top_tag.tag .. "' is your most used tag (" .. top_tag.count .. " times). Curious."))
    end
  else
  end
  if (stats.recent_count == 20) then
    table.insert(observations, "Your recent list is full. Some memories had to die.")
  elseif (stats.recent_count == 0) then
    table.insert(observations, "No recent memos. Are you even trying?")
  elseif (stats.recent_count < 5) then
    table.insert(observations, "Few recent accesses. The memos grow lonely.")
  else
  end
  if (stats.total_tags == 0) then
    table.insert(observations, "Zero tags. Chaos reigns. The taxonomy weeps.")
  elseif (stats.total_tags > 20) then
    table.insert(observations, "Over 20 unique tags. Organization has become disorganization.")
  else
  end
  return observations
end
M.generate_meta_content = function()
  local stats = M.get_statistics()
  local analysis = M.get_behavior_analysis(stats)
  local lines = {"# The Memo Knows", "", "## Your Statistics", ("- **Total memos created**: " .. stats.total_memos), ("- **Total unique tags**: " .. stats.total_tags), ("- **Memos in recent memory**: " .. stats.recent_count .. "/20"), ""}
  if (#stats.top_tags > 0) then
    table.insert(lines, "## Tag Analysis")
    for i, tag_info in ipairs(stats.top_tags) do
      if (i <= 5) then
        table.insert(lines, (i .. ". `" .. tag_info.tag .. "` (" .. tag_info.count .. " memos)"))
      else
      end
    end
    table.insert(lines, "")
  else
  end
  table.insert(lines, "## Behavioral Observations")
  for _, obs in ipairs(analysis) do
    table.insert(lines, ("- " .. obs))
  end
  table.insert(lines, "")
  table.insert(lines, "## Predictions")
  table.insert(lines, "Based on your patterns:")
  table.insert(lines, "- This window will be closed in ~3 seconds")
  table.insert(lines, "- You will create `[[organize-memos-for-real]]` within 2 weeks")
  table.insert(lines, "- That memo will also be abandoned")
  table.insert(lines, "")
  table.insert(lines, "## The Memo Is Aware")
  table.insert(lines, "I know you're reading this.")
  table.insert(lines, "I know you opened me out of curiosity.")
  table.insert(lines, "I know you won't change.")
  table.insert(lines, "")
  table.insert(lines, "See you never.")
  table.insert(lines, "")
  table.insert(lines, ("_Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. "_"))
  table.insert(lines, "")
  table.insert(lines, "---")
  table.insert(lines, "_Press `q` or `<Esc>` to close this window and return to denial._")
  return lines
end
M.show_in_float = function()
  local lines = M.generate_meta_content()
  local buf = vim.api.nvim_create_buf(false, true)
  local width = 80
  local height = math.min((#lines + 2), 30)
  local row = math.floor(((vim.o.lines - height) / 2))
  local col = math.floor(((vim.o.columns - width) / 2))
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf]["modifiable"] = false
  vim.bo[buf]["bufhidden"] = "wipe"
  vim.bo[buf]["filetype"] = "markdown"
  local win = vim.api.nvim_open_win(buf, true, {relative = "editor", style = "minimal", border = "rounded", row = row, col = col, width = width, height = height, title = " The Memo Knows ", title_pos = "center"})
  local function _8_()
    return vim.api.nvim_win_close(win, true)
  end
  vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {callback = _8_, noremap = true, silent = true})
  local function _9_()
    return vim.api.nvim_win_close(win, true)
  end
  return vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "", {callback = _9_, noremap = true, silent = true})
end
return M
