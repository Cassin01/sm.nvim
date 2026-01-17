# sm.nvim - Simple Memo

A memo management module for Neovim with tagging, wiki-style linking, and picker integration.

## Features

- Create timestamped memos (`YYYYMMDD_HHMMSS_{title}.md`)
- YAML frontmatter with tags
- Wiki-style `[[links]]` between memos
- Floating window UI with Copilot support
- **Picker-agnostic API** - works with any picker (fzf-lua, snacks.nvim, mini.pick, wf.nvim, etc.)

## Storage

Memos are stored in `~/.cache/nvim/sm/memos/` (default, configurable via `memos_dir`)

## Usage

### Keymaps (Example)

This plugin does not set any keymaps by default. Here's an example configuration in Lua:

```lua
local sm = require("sm")

vim.keymap.set("n", "<Leader>mn", sm.create, { desc = "[sm] New memo with timestamp" })
vim.keymap.set("n", "<Leader>mo", sm.open_last, { desc = "[sm] Open last edited" })
vim.keymap.set("n", "<Leader>mf", sm.follow_link, { desc = "[sm] Follow wiki link under cursor" })
vim.keymap.set("n", "<Leader>ma", sm.add_tag, { desc = "[sm] Add tag to current memo" })
```

### Commands

| Command | Description |
|---------|-------------|
| `:SmNew [title]` | Create new memo (prompts if no title) |
| `:SmOpen` | Open last edited memo |
| `:SmAddTag [tag]` | Add tag to current memo |
| `:SmFollowLink` | Follow wiki link under cursor |

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
  memos_dir = "~/.cache/nvim/sm/memos",
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

## API

### Memo Operations

| Function | Description |
|----------|-------------|
| `sm.create(?title)` | Create new memo |
| `sm.open_last()` | Open last edited memo |

### Tag Operations

| Function | Description |
|----------|-------------|
| `sm.list_all_tags()` | Get all tags (for completion) |
| `sm.add_tag(?tag)` | Add tag to current memo |

### Link Operations

| Function | Description |
|----------|-------------|
| `sm.follow_link()` | Follow wiki link under cursor |
