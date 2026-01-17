# CLAUDE.md

## Build

```bash
make        # Compile Fennel to Lua
make test   # Run tests
make clean  # Remove generated Lua files
```

## Project Structure

- `fnl/sm/*.fnl` - Source files (Fennel)
- `lua/sm/*.lua` - Generated files (do not edit directly)
- `doc/sm.txt` - Vim help documentation

## Important

- **Source language**: Fennel (Lisp dialect compiling to Lua)
- **Generated files**: All `lua/` files are auto-generated from `fnl/`
- **Edit only**: `.fnl` files, never `.lua` files directly

## Test-Driven Development (TDD)

### Philosophy

TDD ensures correctness and enables fearless refactoring. In this project:

1. **Tests are the specification** - Write tests that describe expected behavior before implementation
2. **Fennel tests, Lua execution** - Tests are written in `*_test.fnl`, compiled to `*_test.lua`, run via `lua`
3. **Simple assertions** - Use `(assert condition "module-function: description")` pattern
4. **Mock early** - Mock `vim` and dependencies BEFORE requiring the module under test

### Red-Green-Refactor Cycle

```
RED    → Write failing test describing expected behavior
GREEN  → Write minimal code to make test pass
REFACTOR → Improve code while keeping tests green
```

**Critical**: Never skip steps. Never write implementation code without a failing test first.

### Workflow

#### Adding a New Feature

1. Create or open `fnl/sm/module_test.fnl`
2. Write test for the new behavior (will fail - RED)
3. Run `make test` - confirm test fails with expected error
4. Implement minimal code in `fnl/sm/module.fnl` (GREEN)
5. Run `make test` - confirm test passes
6. Refactor if needed, keeping tests green

#### Fixing a Bug

1. Write a test that reproduces the bug (fails - RED)
2. Fix the bug in source (GREEN)
3. Run `make test` - confirm fix and no regressions

#### Refactoring

1. Ensure all existing tests pass
2. Refactor code
3. Run `make test` - all tests must still pass

### Test File Structure

```fennel
;;; sm/module_test.fnl - Tests for module

;; 1. Setup Lua path
(set package.path (.. "./lua/?.lua;" package.path))

;; 2. Mock vim API BEFORE requiring modules
(when (not _G.vim)
  (fn deepcopy [t]
    (if (= (type t) :table)
      (let [copy {}]
        (each [k v (pairs t)]
          (tset copy k (deepcopy v)))
        copy)
      t))
  (set _G.vim {:tbl_deep_extend (fn [_ t1 t2]
                                  (let [result {}]
                                    (each [k v (pairs t1)] (tset result k v))
                                    (each [k v (pairs t2)] (tset result k v))
                                    result))
               :deepcopy deepcopy
               :fn {:stdpath (fn [which] "/tmp/test-nvim-cache")
                    :fnamemodify (fn [path modifier] path)}}))

;; 3. Mock dependencies (optional)
(tset package.loaded :sm.other-module
      {:some_fn (fn [] "mocked result")})

;; 4. Require module under test
(local M (require :sm.module))

;; 5. Tests grouped by function
(assert (= (M.function_name "input") "expected") "function_name: description")

;; 6. Success message
(print "module_test.lua: All tests passed")
```

### Writing Tests

#### Assertion Pattern

```fennel
(assert (= actual expected) "function-name: what is being tested")
```

**Naming convention**: `"function-name: concise description of expectation"`

Examples:
```fennel
(assert (= (M.parse_link "[[memo]]") "memo") "parse_link: simple link")
(assert (= (M.parse_link "no link") nil) "parse_link: returns nil for no link")
(assert (= (length result.tags) 2) "parse_frontmatter: tag count")
```

#### Testing Return Values

```fennel
;; Simple equality
(assert (= (M.sanitize_title "Hello!") "hello") "sanitize_title: removes punctuation")

;; Table properties
(let [result (M.get_memo_info "/path/to/memo.md")]
  (assert (= result.filename "memo.md") "get_memo_info: extracts filename")
  (assert (= result.title "memo") "get_memo_info: extracts title"))

;; Pattern matching
(let [filename (M.generate_filename "test")]
  (assert (filename:match "^%d+_%d+_test%.md$") "generate_filename: correct format"))
```

### Mocking Patterns

#### vim API Mock (Required)

```fennel
(when (not _G.vim)
  (set _G.vim {:fn {:fnamemodify (fn [path modifier]
                                   (if (= modifier ":t")
                                       (path:match "([^/]+)$")
                                       path))
                    :isdirectory (fn [path] 0)
                    :stdpath (fn [which] "/tmp/test-nvim-cache")}
               :api {:nvim_put (fn [lines mode after follow] nil)}
               :notify (fn [msg level] nil)
               :tbl_deep_extend (fn [_ t1 t2]
                                  (let [result {}]
                                    (each [k v (pairs t1)] (tset result k v))
                                    (each [k v (pairs t2)] (tset result k v))
                                    result))}))
```

#### Module Dependency Mock

```fennel
;; Mock BEFORE requiring the module under test
(tset package.loaded :sm.config
      {:get (fn [] {:date_format "%Y%m%d_%H%M%S"})
       :get_memos_dir (fn [] "/tmp/test-memos")})
```

#### Call Tracking Mock

```fennel
(var call-log [])

(tset package.loaded :sm.memo
      {:open (fn [filepath]
               (table.insert call-log {:fn "open" :arg filepath})
               true)})

;; After test
(assert (= (length call-log) 1) "action: called open once")
(assert (= (. call-log 1 :arg) "/expected/path") "action: correct path")
```

### Anti-Patterns

#### DO NOT: Write Code Before Tests

```fennel
;; WRONG: Implementation first
(fn M.new-feature [] ...)  ;; NO! Write test first

;; RIGHT: Test first, then implement
```

#### DO NOT: Require Module Before Mocking

```fennel
;; WRONG: Module loads real dependencies
(local M (require :sm.module))
(tset package.loaded :sm.config {...})  ;; Too late!

;; RIGHT: Mock before require
(tset package.loaded :sm.config {...})
(local M (require :sm.module))
```

#### DO NOT: Test Implementation Details

```fennel
;; WRONG: Testing internal state
(assert (= M._internal-counter 5) "counter incremented")

;; RIGHT: Test observable behavior
(assert (= (M.get-count) 5) "get-count: returns accumulated value")
```

### Running Tests

```bash
make        # Compile all .fnl to .lua
make test   # Run all *_test.lua files

# Run single test (after make)
lua lua/sm/module_test.lua
```

### Test Coverage Checklist

Before marking a module complete:

- [ ] All public functions have tests
- [ ] Edge cases tested (nil, empty, invalid input)
- [ ] Error conditions handled and tested
- [ ] Tests run successfully: `make test`

## Git

- Use **English** for commit messages
- Use **English** for PR titles and descriptions
