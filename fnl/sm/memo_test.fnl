;;; sm/memo_test.fnl - Tests for memo

;; Setup Lua path for compiled modules
(set package.path (.. "./lua/?.lua;" package.path))

;; Mock dependencies BEFORE requiring modules
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
               :fn {:fnamemodify (fn [path modifier]
                                   (if (= modifier ":t")
                                       (path:match "([^/]+)$")
                                       path))
                    :stdpath (fn [which] "/tmp/test-nvim-cache")}}))

;; Mock state module to avoid circular dependency issues
(tset package.loaded :sm.state {:set_last_edited (fn [])
                                 :add_recent (fn [])
                                 :load (fn [] {})})

;; Mock git module BEFORE requiring memo
(tset package.loaded :sm.git {:get_repo_tag (fn [] nil)
                               :is_git_repo (fn [] false)})

(local M (require :sm.memo))

;; Test sanitize_title
(assert (= (M._sanitize_title "Hello World!") "hello-world") "sanitize: spaces and punctuation")
(assert (= (M._sanitize_title "  Test  ") "test") "sanitize: trim whitespace")
(assert (= (M._sanitize_title "My--Title") "my-title") "sanitize: collapse dashes")
(assert (= (M._sanitize_title "CamelCase") "camelcase") "sanitize: lowercase")
(assert (= (M._sanitize_title "日本語") "日本語") "sanitize: preserve Japanese")
(assert (= (M._sanitize_title "日本語 Test") "日本語-test") "sanitize: Japanese with ASCII")
(assert (= (M._sanitize_title "記号！テスト") "記号！テスト") "sanitize: preserve full-width punctuation")

;; Test generate_filename format
(let [filename (M.generate_filename "test")]
  (assert (filename:match "^%d+_%d+_test%.md$") "filename: format YYYYMMDD_HHMMSS_title.md"))

;; Test generate_template
(let [content (M.generate_template "Test Title")]
  (assert (content:match "^%-%-%-") "template: starts with frontmatter")
  (assert (content:match "tags: %[%]") "template: has empty tags")
  (assert (content:match "# Test Title") "template: has title heading"))

;; Test get_memo_info
(let [info (M.get_memo_info "/path/to/20260117_143052_my-memo.md")]
  (assert (= info.filename "20260117_143052_my-memo.md") "info: filename")
  (assert (= info.date "20260117_143052") "info: date")
  (assert (= info.title "my memo") "info: title with spaces"))

;; Test generate_template with initial tags
(let [content (M.generate_template "Test" ["tag1" "tag2"])]
  (assert (content:match "tags: %[tag1, tag2%]") "template: includes initial tags"))

;; Test generate_template with empty initial tags
(let [content (M.generate_template "Test" [])]
  (assert (content:match "tags: %[%]") "template: empty tags when none provided"))

;; Test generate_template with nil initial tags (backward compatibility)
(let [content (M.generate_template "Test")]
  (assert (content:match "tags: %[%]") "template: empty tags when nil provided"))

;; Test auto_tag_git_repo integration
;; This tests the full flow: config enabled → git repo detected → tag added
(do
  ;; Clear package.loaded to allow re-mocking
  (tset package.loaded :sm.config nil)
  (tset package.loaded :sm.git nil)
  (tset package.loaded :sm.memo nil)

  ;; Mock config with auto_tag_git_repo=true
  (tset package.loaded :sm.config
        {:get (fn []
                {:auto_tag_git_repo true
                 :date_format "%Y%m%d_%H%M%S"
                 :template ["---" "tags: [%tags%]" "created: %date%" "---" "" "# %title%" ""]})
         :get_memos_dir (fn [] "/tmp/test-memos")})

  ;; Mock git module to return a tag
  (tset package.loaded :sm.git
        {:get_repo_tag (fn [] "test-repo")
         :is_git_repo (fn [] true)})

  ;; Mock state module
  (tset package.loaded :sm.state {:set_last_edited (fn [])
                                   :add_recent (fn [])
                                   :load (fn [] {})})

  ;; Re-require memo with new mocks
  (local M2 (require :sm.memo))

  ;; Verify get_initial_tags returns the repo tag
  (let [tags (M2._get_initial_tags)]
    (assert (= (length tags) 1) "auto_tag: returns one tag")
    (assert (= (. tags 1) "test-repo") "auto_tag: returns correct repo name"))

  ;; Verify generate_template includes the tag when passed initial tags
  (let [content (M2.generate_template "Test" (M2._get_initial_tags))]
    (assert (content:match "tags: %[test%-repo%]") "auto_tag: template includes repo tag")))

;; Test split_height config sets window height
(do
  ;; Clear package.loaded for fresh mocks
  (tset package.loaded :sm.config nil)
  (tset package.loaded :sm.git nil)
  (tset package.loaded :sm.memo nil)

  ;; Track nvim_win_set_height calls
  (var set_height_calls [])
  (when (not _G.vim.api)
    (set _G.vim.api {}))
  (tset _G.vim.api :nvim_win_set_height
        (fn [win height]
          (table.insert set_height_calls {:win win :height height})))

  ;; Mock config with split_height
  (tset package.loaded :sm.config
        {:get (fn []
                {:split_height 15
                 :copilot_integration false
                 :date_format "%Y%m%d_%H%M%S"
                 :template ["---" "# %title%" ""]})
         :get_memos_dir (fn [] "/tmp/test-memos")})

  ;; Mock other dependencies
  (tset package.loaded :sm.git {:get_repo_tag (fn [] nil) :is_git_repo (fn [] false)})
  (tset package.loaded :sm.state {:set_last_edited (fn []) :add_recent (fn []) :load (fn [] {})})

  ;; Mock vim functions needed by open_in_split
  (tset _G.vim.fn :bufadd (fn [filepath] 1))
  (tset _G.vim.fn :bufload (fn [buf] nil))
  ;; vim.bo[buf] and vim.wo need metatable for buffer/window-specific access
  (set _G.vim.bo (setmetatable {} {:__index (fn [] {})}))
  (set _G.vim.wo (setmetatable {} {:__index (fn [] {})}))
  (tset _G.vim :cmd (fn [cmd] nil))
  (tset _G.vim.api :nvim_win_set_buf (fn [win buf] nil))

  ;; Re-require memo with mocks
  (local M3 (require :sm.memo))

  ;; Call open_in_split
  (M3.open_in_split "/tmp/test-memos/test.md")

  ;; Verify nvim_win_set_height was called with correct value
  (assert (= (length set_height_calls) 1) "split_height: nvim_win_set_height called once")
  (assert (= (. set_height_calls 1 :height) 15) "split_height: height set to config value"))

(print "memo_test.lua: All tests passed")
