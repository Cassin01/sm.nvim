<div align="center">

# sm.nvim

[![Neovim](https://img.shields.io/badge/Neovim-0.9+-57A143?logo=neovim&logoColor=white)](https://neovim.io/)
[![Fennel](https://img.shields.io/badge/Made_with-Fennel-yellow)](https://fennel-lang.org/)
[![CI](https://github.com/Cassin01/sm.nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/Cassin01/sm.nvim/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/Cassin01/sm.nvim)](LICENSE)

**Simple Memo for Neovim**

Timestamped memos with wiki-style linking, right in your editor.

![demo](assets/demo.gif)

[Features](#-features) •
[Quick Start](#-quick-start) •
[Configuration](#%EF%B8%8F-configuration) •
[Picker Integration](#-picker-integration) •
[API](#-api)

</div>

---

## ✨ Features

- **Timestamped memos** — Files named `YYYYMMDD_HHMMSS_{title}.md`
- **YAML frontmatter** — Tags, creation date, and metadata
- **Wiki-style linking** — Connect memos with `[[links]]`
- **Current buffer editing** — Opens memos in your current buffer
- **Git auto-tagging** — Automatically tag memos with repository name
- **Picker-agnostic** — Works with fzf-lua, snacks.nvim, mini.pick, or any picker

## 🚀 Quick Start

### 1. Install with lazy.nvim

```lua
{
  "Cassin01/sm.nvim",
  config = function()
    require("sm").setup({
      -- memos_dir = "~/.cache/nvim/sm/memos",
      -- state_file = "~/.cache/nvim/sm/state.json",
      -- date_format = "%Y%m%d_%H%M%S",
      -- auto_tag_git_repo = false,
      -- copilot_integration = false,
    })

    -- Buffer-local keymaps for memo files
    local group = vim.api.nvim_create_augroup("sm_user_keymaps", { clear = true })
    vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
      group = group,
      pattern = require("sm").autocmd_pattern(),
      callback = function(args)
        local buf = args.buf
        vim.keymap.set("n", "<leader>mt", require("sm").buf_add_tag, { buffer = buf, desc = "Add tag" })
        vim.keymap.set("n", "<leader>mf", require("sm").buf_follow_link, { buffer = buf, desc = "Follow link" })
      end,
    })
  end,
  keys = {
    { "<Leader>mn", function() require("sm").create() end, desc = "New memo" },
    { "<Leader>mo", function() require("sm").open_last() end, desc = "Open last memo" },
  },
}
```

### 2. Create your first memo

```
:SmNew meeting notes
```

### 3. Browse your memos

```
:SmOpen
```

That's it! Your memos are saved to `~/.cache/nvim/sm/memos/` by default.

## 📦 Installation

<details>
<summary><b>lazy.nvim</b></summary>

```lua
{
  "Cassin01/sm.nvim",
  config = function()
    require("sm").setup({
      -- your options here
    })
  end,
}
```

</details>

## ⚙️ Configuration

```lua
require("sm").setup({
  memos_dir = "~/.cache/nvim/sm/memos",  -- Where memos are stored
  auto_tag_git_repo = true,              -- Auto-tag with git repo name
})
```

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `memos_dir` | `~/.cache/nvim/sm/memos` | Directory where memos are stored |
| `state_file` | `~/.cache/nvim/sm/state.json` | JSON file for persistent state (last edited, recent memos) |
| `date_format` | `"%Y%m%d_%H%M%S"` | Format string for timestamp in filenames (see `os.date()`) |
| `auto_tag_git_repo` | `false` | Auto-tag new memos with git repo name (sanitized: "sm.nvim" → "sm-nvim") |
| `copilot_integration` | `false` | Attach Copilot to memo buffers (requires copilot.vim) |
| `template` | See below | Template for new memo content (supports `%date%`, `%title%`, `%tags%` placeholders) |

## 📋 Commands

| Command | Description |
|---------|-------------|
| `:SmNew [title]` | Create new memo (prompts if no title) |
| `:SmOpen` | Open last edited memo |
| `:SmAddTag [tag]` | Add tag to current memo |
| `:SmFollowLink` | Follow wiki link under cursor |
| `:SmMetaMemo` | Display self-aware memo statistics (easter egg) |

## 🗒️ Memo Format

```markdown
---
tags: [work, ideas]
created: 2026-01-17T14:30:52
---

# Meeting Notes

Link to another memo: [[20260115_project-ideas]]

Your content here...
```

### Wiki Links

In memo buffers, place your cursor on `[[memo-name]]` and press `gf` (or `:SmFollowLink`) to follow the link. Links match by partial filename (case-insensitive).

## 🔌 Picker Integration

sm.nvim provides a **picker-agnostic API** that works with any picker. See the API reference below.

<details>
<summary><b>fzf-lua example</b></summary>

```lua
local api = require("sm.api")
local fzf = require("fzf-lua")

local function create_memo_previewer(lookup)
  local builtin = require("fzf-lua.previewer.builtin")
  local MemoPreview = builtin.buffer_or_file:extend()

  function MemoPreview:new(o, opts, fzf_win)
    o = o or {}
    o.render_markdown = false
    MemoPreview.super.new(self, o, opts, fzf_win)
    setmetatable(self, MemoPreview)
    return self
  end

  function MemoPreview:parse_entry(entry_str)
    local path = lookup[entry_str]
    if not path then
      return {}
    end
    return { path = path, line = 1, col = 1 }
  end

  return MemoPreview
end

-- List and open memos
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
    previewer = create_memo_previewer(lookup),
    actions = {
      ["default"] = function(selected)
        if selected[1] then
          api.open_memo(lookup[selected[1]])
        end
      end,
    },
  })
end, { desc = "[sm] List memos" })

-- Grep within memos directory
vim.keymap.set("n", "<Leader>mg", function()
  fzf.live_grep({ cwd = api.get_memos_dir() })
end, { desc = "Grep memos" })

-- Browse memos by tag
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
            previewer = create_memo_previewer(memo_lookup),
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
end, { desc = "[sm] Browse tags" })

-- Insert wiki-style link
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
end, { desc = "[sm] Insert link" })
```

</details>

<details>
<summary><b>snacks.nvim example</b></summary>

```lua
local api = require("sm.api")
local Snacks = require("snacks")

vim.keymap.set("n", "<Leader>ml", function()
  Snacks.picker.pick({
    title = "Memos",
    items = api.get_memos(),
    format = function(item) return item.text end,
    on_select = function(item) api.open_memo(item.value) end,
  })
end, { desc = "List memos" })
```

</details>

<details>
<summary><b>mini.pick example</b></summary>

```lua
local api = require("sm.api")
local MiniPick = require("mini.pick")

vim.keymap.set("n", "<Leader>ml", function()
  local entries = api.get_memos()
  MiniPick.start({
    source = {
      items = entries,
      name = "Memos",
      show = function(buf_id, items, query)
        local lines = vim.tbl_map(function(item) return item.text end, items)
        vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
      end,
      choose = function(item) api.open_memo(item.value) end,
    },
  })
end, { desc = "List memos" })
```

</details>

## 📖 API

### Core Functions

```lua
local sm = require("sm")

sm.create(title?)      -- Create new memo
sm.open_last()         -- Open last edited memo
sm.buf_add_tag(tag?)   -- Add tag to current buffer's memo
sm.buf_follow_link()   -- Follow wiki link under cursor
sm.list_all_tags()     -- Get all tags (for completion)
sm.autocmd_pattern()   -- Get pattern for autocommands (BufNewFile/BufRead)
```

### Picker API

```lua
local api = require("sm.api")

-- Data functions (return picker-ready entries)
api.get_memos()            -- All memos: {value, text, ordinal, info, tags}
api.get_tags()             -- All tags: {value, text, ordinal, count}
api.get_memos_by_tag(tag)  -- Filtered memos: {value, text, ordinal, info}
api.get_memos_for_link()   -- For links: {value, text, ordinal, filepath}

-- Action functions
api.open_memo(filepath)    -- Open memo file
api.insert_link(filename)  -- Insert [[filename]] at cursor

-- Utility
api.get_memos_dir()        -- Get memos directory path
```

## 🎹 Buffer Keymaps

Use `autocmd_pattern()` with native autocommands to set buffer-local keymaps for memo files:

```lua
local group = vim.api.nvim_create_augroup("sm_user_keymaps", { clear = true })

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = group,
  pattern = require("sm").autocmd_pattern(),
  callback = function(args)
    local buf = args.buf
    vim.keymap.set("n", "<leader>mt", require("sm").buf_add_tag, { buffer = buf, desc = "Add tag" })
    vim.keymap.set("n", "<leader>mf", require("sm").buf_follow_link, { buffer = buf, desc = "Follow link" })
  end,
})
```

### Events

| Event | Trigger |
|-------|---------|
| `BufNewFile` | New memo created via `create()` |
| `BufRead` | Existing memo opened via `api.open_memo()`, `open_last()` |

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

This plugin is written in [Fennel](https://fennel-lang.org/), a Lisp that compiles to Lua.

## 📄 License

[Apache-2.0](LICENSE) © Cassin01
