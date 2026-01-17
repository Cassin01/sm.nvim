# sm.nvim - Simple Memo

A memo management module for Neovim with tagging, wiki-style linking, and picker integration.

## Features

- Create timestamped memos (`YYYYMMDD_HHMMSS_{title}.md`)
- YAML frontmatter with tags
- Wiki-style `[[links]]` between memos
- Floating window UI with Copilot support
- **Picker-agnostic API** - works with any picker (Telescope, fzf-lua, snacks.nvim, mini.pick, wf.nvim)

## Storage

Memos are stored in `~/.cache/nvim/sm/memos/` (default, configurable via `memos-dir`)

## Usage

### Keymaps (Example)

This plugin does not set any keymaps by default. Here's an example configuration in Lua:

```lua
local sm = require("sm")

vim.keymap.set("n", "<Leader>mn", sm.create, { desc = "[sm] New memo with timestamp" })
vim.keymap.set("n", "<Leader>ml", sm.list, { desc = "[sm] List all memos" })
vim.keymap.set("n", "<Leader>mg", sm.grep, { desc = "[sm] Grep memo contents" })
vim.keymap.set("n", "<Leader>mt", sm.tags, { desc = "[sm] Browse by tag" })
vim.keymap.set("n", "<Leader>ms", sm["search-by-tag"], { desc = "[sm] Search by tag" })
vim.keymap.set("n", "<Leader>mo", sm["open-last"], { desc = "[sm] Open last edited" })
vim.keymap.set("n", "<Leader>mi", sm["insert-link"], { desc = "[sm] Insert wiki link" })
vim.keymap.set("n", "<Leader>ma", sm["add-tag"], { desc = "[sm] Add tag to current memo" })
```

### Commands

| Command | Description |
|---------|-------------|
| `:SmNew [title]` | Create new memo (prompts if no title) |
| `:SmOpen` | Open last edited memo |
| `:SmList` | Picker for all memos |
| `:SmGrep` | Live grep through memo contents |
| `:SmTags` | Browse memos by tag |
| `:SmTagSearch {tag}` | Search memos with specific tag |
| `:SmAddTag [tag]` | Add tag to current memo |
| `:SmFollowLink` | Follow wiki link under cursor |
| `:SmInsertLink` | Insert wiki link from picker |

### Memo Format

```markdown
---
tags: [work, ideas]
created: 2026-01-17T14:30:52
---

# Meeting Notes

Link to another memo: [[20260115_project-ideas]]

Content here...
```

### Wiki Links

In memo buffers, press `gf` on `[[memo-name]]` to follow the link.
Links match by partial filename (case-insensitive).

## Configuration

```lua
local sm = require("sm")
sm.setup({
  ["memos-dir"] = "~/.cache/nvim/sm/memos",
  window = {
    width = 80,
    height = 30,
    border = "rounded",
  },
})
```

## Picker Integration

sm.nvim provides a public API (`require("sm.api")`) that works with any picker.

### API Reference

```lua
local api = require("sm.api")

-- Data functions (return picker-ready entries)
api.get_memos()           -- All memos: {value=filepath, text=display, ordinal, info, tags}
api.get_tags()            -- All tags:  {value=tag, text=display, ordinal, count}
api.get_memos_by_tag(tag) -- Filtered:  {value=filepath, text=display, ordinal, info}
api.get_memos_for_link()  -- For links: {value=filename, text=display, ordinal, filepath}

-- Action functions (use as selection callbacks)
api.open_memo(filepath)   -- Open memo in floating window
api.insert_link(filename) -- Insert [[filename]] at cursor

-- Utility
api.get_memos_dir()       -- Get memos directory path (for grep)
```

### Picker Examples

<details>
<summary><b>wf.nvim</b></summary>

```lua
local api = require("sm.api")
local wf = require("wf")

vim.keymap.set("n", "<Leader>ml", function()
  local entries = api.get_memos()
  local choices = {}
  for _, entry in ipairs(entries) do
    choices[entry.text] = function()
      api.open_memo(entry.value)
    end
  end
  wf.select(choices, { prompt = "Memos" })
end, { desc = "List memos" })

vim.keymap.set("n", "<Leader>mt", function()
  local entries = api.get_tags()
  local choices = {}
  for _, entry in ipairs(entries) do
    choices[entry.text] = function()
      local memo_entries = api.get_memos_by_tag(entry.value)
      local memo_choices = {}
      for _, e in ipairs(memo_entries) do
        memo_choices[e.text] = function()
          api.open_memo(e.value)
        end
      end
      wf.select(memo_choices, { prompt = "Memos [" .. entry.value .. "]" })
    end
  end
  wf.select(choices, { prompt = "Tags" })
end, { desc = "Browse tags" })

vim.keymap.set("n", "<Leader>mi", function()
  local entries = api.get_memos_for_link()
  local choices = {}
  for _, entry in ipairs(entries) do
    choices[entry.text] = function()
      api.insert_link(entry.value)
    end
  end
  wf.select(choices, { prompt = "Insert Link" })
end, { desc = "Insert link" })
```

</details>

<details>
<summary><b>telescope.nvim</b></summary>

If telescope.nvim is installed, the default commands (`sm.list()`, `sm.grep()`, etc.) work out of the box.

For manual configuration:

```lua
local api = require("sm.api")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

vim.keymap.set("n", "<Leader>ml", function()
  local entries = api.get_memos()
  pickers.new({}, {
    prompt_title = "Memos",
    finder = finders.new_table({
      results = entries,
      entry_maker = function(entry)
        return {
          value = entry.value,
          display = entry.text,
          ordinal = entry.ordinal,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = previewers.new_buffer_previewer({
      title = "Memo Preview",
      define_preview = function(self, entry, bufnr)
        conf.buffer_previewer_maker(entry.value, bufnr, {})
      end,
    }),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        api.open_memo(selection.value)
      end)
      return true
    end,
  }):find()
end, { desc = "List memos" })

vim.keymap.set("n", "<Leader>mg", function()
  require("telescope.builtin").live_grep({
    cwd = api.get_memos_dir(),
    prompt_title = "Grep Memos",
    glob_pattern = "*.md",
  })
end, { desc = "Grep memos" })

vim.keymap.set("n", "<Leader>mt", function()
  local entries = api.get_tags()
  pickers.new({}, {
    prompt_title = "Tags",
    finder = finders.new_table({
      results = entries,
      entry_maker = function(entry)
        return {
          value = entry.value,
          display = entry.text,
          ordinal = entry.ordinal,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        local tag = selection.value
        -- Show memos by tag
        local memo_entries = api.get_memos_by_tag(tag)
        pickers.new({}, {
          prompt_title = "Memos [" .. tag .. "]",
          finder = finders.new_table({
            results = memo_entries,
            entry_maker = function(e)
              return { value = e.value, display = e.text, ordinal = e.ordinal }
            end,
          }),
          sorter = conf.generic_sorter({}),
          attach_mappings = function(pb)
            actions.select_default:replace(function()
              actions.close(pb)
              local sel = action_state.get_selected_entry()
              api.open_memo(sel.value)
            end)
            return true
          end,
        }):find()
      end)
      return true
    end,
  }):find()
end, { desc = "Browse tags" })

vim.keymap.set("n", "<Leader>mi", function()
  local entries = api.get_memos_for_link()
  pickers.new({}, {
    prompt_title = "Insert Link",
    finder = finders.new_table({
      results = entries,
      entry_maker = function(entry)
        return {
          value = entry.value,
          display = entry.text,
          ordinal = entry.ordinal,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        api.insert_link(selection.value)
      end)
      return true
    end,
  }):find()
end, { desc = "Insert link" })
```

</details>

<details>
<summary><b>snacks.nvim</b></summary>

```lua
local api = require("sm.api")
local Snacks = require("snacks")

vim.keymap.set("n", "<Leader>ml", function()
  local entries = api.get_memos()
  Snacks.picker.pick({
    source = "sm_memos",
    items = function()
      local items = {}
      for _, entry in ipairs(entries) do
        table.insert(items, {
          text = entry.text,
          file = entry.value,
        })
      end
      return items
    end,
    format = "file",
    confirm = function(picker, item)
      picker:close()
      api.open_memo(item.file)
    end,
  })
end, { desc = "List memos" })

vim.keymap.set("n", "<Leader>mg", function()
  Snacks.picker.grep({ dirs = { api.get_memos_dir() } })
end, { desc = "Grep memos" })

vim.keymap.set("n", "<Leader>mt", function()
  local entries = api.get_tags()
  Snacks.picker.pick({
    source = "sm_tags",
    items = function()
      local items = {}
      for _, entry in ipairs(entries) do
        table.insert(items, {
          text = entry.text,
          tag = entry.value,
        })
      end
      return items
    end,
    confirm = function(picker, item)
      picker:close()
      local memo_entries = api.get_memos_by_tag(item.tag)
      Snacks.picker.pick({
        source = "sm_memos_by_tag",
        items = function()
          local tag_items = {}
          for _, e in ipairs(memo_entries) do
            table.insert(tag_items, { text = e.text, file = e.value })
          end
          return tag_items
        end,
        confirm = function(p2, item2)
          p2:close()
          api.open_memo(item2.file)
        end,
      })
    end,
  })
end, { desc = "Browse tags" })

vim.keymap.set("n", "<Leader>mi", function()
  local entries = api.get_memos_for_link()
  Snacks.picker.pick({
    source = "sm_links",
    items = function()
      local items = {}
      for _, entry in ipairs(entries) do
        table.insert(items, {
          text = entry.text,
          filename = entry.value,
        })
      end
      return items
    end,
    confirm = function(picker, item)
      picker:close()
      api.insert_link(item.filename)
    end,
  })
end, { desc = "Insert link" })
```

</details>

<details>
<summary><b>fzf-lua</b></summary>

```lua
local api = require("sm.api")
local fzf = require("fzf-lua")

vim.keymap.set("n", "<Leader>ml", function()
  local entries = api.get_memos()
  local items = {}
  local lookup = {}
  for _, entry in ipairs(entries) do
    table.insert(items, entry.text)
    lookup[entry.text] = entry.value
  end
  fzf.fzf_exec(items, {
    prompt = "Memos> ",
    previewer = "builtin",
    actions = {
      ["default"] = function(selected)
        if selected[1] then
          api.open_memo(lookup[selected[1]])
        end
      end,
    },
  })
end, { desc = "List memos" })

vim.keymap.set("n", "<Leader>mg", function()
  fzf.live_grep({ cwd = api.get_memos_dir() })
end, { desc = "Grep memos" })

vim.keymap.set("n", "<Leader>mt", function()
  local entries = api.get_tags()
  local items = {}
  local lookup = {}
  for _, entry in ipairs(entries) do
    table.insert(items, entry.text)
    lookup[entry.text] = entry.value
  end
  fzf.fzf_exec(items, {
    prompt = "Tags> ",
    actions = {
      ["default"] = function(selected)
        if selected[1] then
          local tag = lookup[selected[1]]
          local memo_entries = api.get_memos_by_tag(tag)
          local memo_items = {}
          local memo_lookup = {}
          for _, e in ipairs(memo_entries) do
            table.insert(memo_items, e.text)
            memo_lookup[e.text] = e.value
          end
          fzf.fzf_exec(memo_items, {
            prompt = "Memos [" .. tag .. "]> ",
            previewer = "builtin",
            actions = {
              ["default"] = function(sel)
                if sel[1] then
                  api.open_memo(memo_lookup[sel[1]])
                end
              end,
            },
          })
        end
      end,
    },
  })
end, { desc = "Browse tags" })

vim.keymap.set("n", "<Leader>mi", function()
  local entries = api.get_memos_for_link()
  local items = {}
  local lookup = {}
  for _, entry in ipairs(entries) do
    table.insert(items, entry.text)
    lookup[entry.text] = entry.value
  end
  fzf.fzf_exec(items, {
    prompt = "Insert Link> ",
    actions = {
      ["default"] = function(selected)
        if selected[1] then
          api.insert_link(lookup[selected[1]])
        end
      end,
    },
  })
end, { desc = "Insert link" })
```

</details>

<details>
<summary><b>mini.pick</b></summary>

```lua
local api = require("sm.api")
local MiniPick = require("mini.pick")

vim.keymap.set("n", "<Leader>ml", function()
  local entries = api.get_memos()
  local items = vim.tbl_map(function(e)
    return { text = e.text, path = e.value }
  end, entries)
  MiniPick.start({
    source = {
      name = "Memos",
      items = items,
      show = function(buf_id, items_to_show, query)
        local lines = vim.tbl_map(function(item) return item.text end, items_to_show)
        vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
      end,
      choose = function(item)
        if item then api.open_memo(item.path) end
      end,
    },
  })
end, { desc = "List memos" })

vim.keymap.set("n", "<Leader>mg", function()
  MiniPick.builtin.grep_live({ cwd = api.get_memos_dir() })
end, { desc = "Grep memos" })

vim.keymap.set("n", "<Leader>mt", function()
  local entries = api.get_tags()
  local items = vim.tbl_map(function(e)
    return { text = e.text, tag = e.value }
  end, entries)
  MiniPick.start({
    source = {
      name = "Tags",
      items = items,
      show = function(buf_id, items_to_show, query)
        local lines = vim.tbl_map(function(item) return item.text end, items_to_show)
        vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
      end,
      choose = function(item)
        if item then
          local memo_entries = api.get_memos_by_tag(item.tag)
          local memo_items = vim.tbl_map(function(e)
            return { text = e.text, path = e.value }
          end, memo_entries)
          MiniPick.start({
            source = {
              name = "Memos [" .. item.tag .. "]",
              items = memo_items,
              show = function(buf_id, its, q)
                local lines = vim.tbl_map(function(i) return i.text end, its)
                vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
              end,
              choose = function(m)
                if m then api.open_memo(m.path) end
              end,
            },
          })
        end
      end,
    },
  })
end, { desc = "Browse tags" })

vim.keymap.set("n", "<Leader>mi", function()
  local entries = api.get_memos_for_link()
  local items = vim.tbl_map(function(e)
    return { text = e.text, filename = e.value }
  end, entries)
  MiniPick.start({
    source = {
      name = "Insert Link",
      items = items,
      show = function(buf_id, items_to_show, query)
        local lines = vim.tbl_map(function(item) return item.text end, items_to_show)
        vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
      end,
      choose = function(item)
        if item then api.insert_link(item.filename) end
      end,
    },
  })
end, { desc = "Insert link" })
```

</details>

## API

### Memo Operations

| Function | Description |
|----------|-------------|
| `sm.create(?title)` | Create new memo |
| `sm.open-last()` | Open last edited memo |
| `sm.list()` | Open memo picker (Telescope if available) |
| `sm.grep()` | Search memo contents |

### Tag Operations

| Function | Description |
|----------|-------------|
| `sm.tags()` | Browse memos by tag |
| `sm.search-by-tag(tag)` | List memos with tag |
| `sm.list-all-tags()` | Get all tags (for completion) |
| `sm.add-tag(?tag)` | Add tag to current memo |

### Link Operations

| Function | Description |
|----------|-------------|
| `sm.follow-link()` | Follow wiki link under cursor |
| `sm.insert-link()` | Insert link via picker |
