# sm.nvim - Simple Memo

A memo management module for Neovim with tagging, Telescope integration, and wiki-style linking.

## Features

- Create timestamped memos (`YYYYMMDD_HHMMSS_{title}.md`)
- YAML frontmatter with tags
- Telescope integration (list, grep, tag browsing)
- Wiki-style `[[links]]` between memos
- Floating window UI with Copilot support

## Storage

Memos are stored in `~/.cache/nvim/sm/memos/`

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
| `:SmList` | Telescope picker for all memos |
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

## API

### Memo Operations

| Function | Description |
|----------|-------------|
| `sm.create(?title)` | Create new memo |
| `sm.open-last()` | Open last edited memo |
| `sm.list()` | Open Telescope memo picker |
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

## Module Structure
