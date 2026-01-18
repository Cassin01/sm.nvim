# Contributing to sm.nvim

Thank you for your interest in contributing to sm.nvim! This guide will help you get started.

## Development Setup

### Prerequisites

- [Lua](https://www.lua.org/) 5.4+
- [Fennel](https://fennel-lang.org/) 1.5.1+
- Neovim 0.9+ (for testing the plugin)

### Getting Started

```bash
# Clone the repository
git clone https://github.com/Cassin01/sm.nvim.git
cd sm.nvim

# Compile Fennel to Lua
make

# Run tests
make test
```

## Project Structure

```
sm.nvim/
├── fnl/sm/           # Source files (Fennel) - EDIT THESE
│   ├── *.fnl         # Module source code
│   └── *_test.fnl    # Test files
├── lua/sm/           # Generated files (DO NOT EDIT)
├── doc/              # Vim help documentation
└── Makefile          # Build system
```

**Important**: This plugin is written in [Fennel](https://fennel-lang.org/), a Lisp dialect that compiles to Lua.

- **ALWAYS** edit `.fnl` files in `fnl/sm/`
- **NEVER** edit `.lua` files in `lua/sm/` directly (they are auto-generated)

## Test-Driven Development (TDD)

We follow strict TDD practices. Every change should follow the Red-Green-Refactor cycle:

### Red-Green-Refactor

```
RED    → Write a failing test describing expected behavior
GREEN  → Write minimal code to make the test pass
REFACTOR → Improve code while keeping tests green
```

### Workflow

#### Adding a New Feature

1. Create or open `fnl/sm/module_test.fnl`
2. Write a test for the new behavior (it will fail - RED)
3. Run `make test` - confirm test fails with expected error
4. Implement minimal code in `fnl/sm/module.fnl` (GREEN)
5. Run `make test` - confirm test passes
6. Refactor if needed, keeping tests green

#### Fixing a Bug

1. Write a test that reproduces the bug (fails - RED)
2. Fix the bug in source (GREEN)
3. Run `make test` - confirm fix and no regressions

### Writing Tests

Test files use simple assertions:

```fennel
;; Assertion pattern
(assert (= actual expected) "function-name: description")

;; Examples
(assert (= (M.parse_link "[[memo]]") "memo") "parse_link: simple link")
(assert (= (M.parse_link "no link") nil) "parse_link: returns nil for no link")
```

### Test File Structure

```fennel
;;; sm/module_test.fnl - Tests for module

;; 1. Setup Lua path
(set package.path (.. "./lua/?.lua;" package.path))

;; 2. Mock vim API BEFORE requiring modules
(when (not _G.vim)
  (set _G.vim {:fn {:fnamemodify (fn [path modifier] path)}
               :tbl_deep_extend (fn [_ t1 t2] ...)}))

;; 3. Mock dependencies (if needed)
(tset package.loaded :sm.other-module
      {:some_fn (fn [] "mocked")})

;; 4. Require module under test
(local M (require :sm.module))

;; 5. Tests
(assert (= (M.function_name "input") "expected") "function_name: description")

;; 6. Success message
(print "module_test.lua: All tests passed")
```

## Build Commands

| Command | Description |
|---------|-------------|
| `make` | Compile all Fennel to Lua |
| `make test` | Run all tests |
| `make clean` | Remove generated Lua files |

## Pull Request Guidelines

### Before Submitting

- [ ] All tests pass (`make test`)
- [ ] Code is written in Fennel (not Lua directly)
- [ ] Lua files are regenerated (`make`)
- [ ] Commit messages are descriptive

### PR Checklist

- [ ] Tests added for new functionality
- [ ] Documentation updated (if needed)
- [ ] No unrelated changes included

## Code Style

- Use snake_case for function names
- Keep functions small and focused
- Mock dependencies before requiring modules in tests
- Use descriptive assertion messages

## Questions?

Feel free to open an issue if you have questions or need help getting started.
