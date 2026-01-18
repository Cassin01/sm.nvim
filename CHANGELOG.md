# Changelog

All notable changes to sm.nvim will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Complete configuration options documentation
- `:SmMetaMemo` easter egg command

### Changed
- Replaced deprecated `nvim_buf_set_option` with `vim.bo`
- Makefile now uses wildcard patterns for automatic file detection

## [0.2.0] - 2026-01-18

### Added
- Git auto-tagging with `auto_tag_git_repo` option
- Centered title input and repositioned memo window to lower left
- Boundary safeguards and error handling for window creation

### Fixed
- Include actual error message in window creation failure notification
- Address critical code issues from static analysis

### Changed
- Comprehensive refactoring based on Copilot code review feedback

## [0.1.0] - 2026-01-15

### Added
- Core memo management functionality
- Timestamped memo files (`YYYYMMDD_HHMMSS_{title}.md`)
- YAML frontmatter with tags and creation date
- Wiki-style `[[links]]` between memos
- Floating window UI for memo editing
- **Picker-agnostic API** - works with any picker (fzf-lua, snacks.nvim, mini.pick, etc.)
- Commands: `:SmNew`, `:SmOpen`, `:SmAddTag`, `:SmFollowLink`

### Changed
- Removed Telescope dependency in favor of generic picker API
- Converted function names from kebab-case to snake_case

### Documentation
- Added comprehensive Vim help documentation (`doc/sm.txt`)
- Added TDD guidelines to CLAUDE.md
- Added AI assistant instructions

## [0.0.1] - Initial Development

### Added
- Initial implementation with basic memo functionality
- Tag management and indexing
- State persistence for last edited memo
- Error handling and caching improvements
