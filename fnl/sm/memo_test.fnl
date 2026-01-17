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

(print "memo_test.lua: All tests passed")
