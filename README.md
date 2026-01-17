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

### Keymaps (`<Space>m` prefix)

| Key | Description |
|-----|-------------|
| `<Space>em` | Quick scratch memo (single file) |
| `<Space>en` | **N**ew memo with timestamp |
| `<Space>el` | **L**ist all memos |
| `<Space>eg` | **G**rep memo contents |
| `<Space>et` | Browse by **t**ag |
| `<Space>es` | **S**earch by tag |
| `<Space>eo` | **O**pen last edited |
| `<Space>ei` | **I**nsert wiki link |

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

```fennel
(local sm (require :sm))
(sm.setup {:memos-dir "~/.cache/nvim/sm/memos"
           :window {:width 80
                    :height 30
                    :border :rounded}})
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

```
fnl/sm/
  init.fnl       -- Public API
  config.fnl     -- Configuration management
  state.fnl      -- State persistence (last edited)
  memo.fnl       -- Core memo CRUD operations
  tags.fnl       -- Tag parsing and indexing
  telescope.fnl  -- Telescope pickers
  links.fnl      -- Wiki-style link handling
```

## Testing

Each module has inline tests. Run with:

```bash
cd ~/.config/nvim
fennel fnl/sm/memo.fnl
fennel fnl/sm/tags.fnl
fennel fnl/sm/links.fnl
fennel fnl/sm/state.fnl
```
