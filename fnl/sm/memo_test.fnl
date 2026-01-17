;;; sm/memo_test.fnl - Tests for memo

;; Setup path for standalone execution
(let [fennel (require :fennel)]
  (set fennel.path (.. "./fnl/?.fnl;" fennel.path)))

;; Mock dependencies BEFORE requiring modules
(when (not _G.vim)
  (set _G.vim {:tbl_deep_extend (fn [_ t1 t2]
                                  (let [result {}]
                                    (each [k v (pairs t1)] (tset result k v))
                                    (each [k v (pairs t2)] (tset result k v))
                                    result))
               :fn {:fnamemodify (fn [path modifier]
                                   (if (= modifier ":t")
                                       (path:match "([^/]+)$")
                                       path))}}))
(tset package.loaded :kaza.file {:nvim-cache (fn [] "/tmp/test-nvim-cache")})

;; Mock state module to avoid circular dependency issues
(tset package.loaded :sm.state {:set-last-edited (fn [])
                                 :add-recent (fn [])
                                 :load (fn [] {})})

(local M (require :sm.memo))

;; Test sanitize-title
(assert (= (M._sanitize-title "Hello World!") "hello-world") "sanitize: spaces and punctuation")
(assert (= (M._sanitize-title "  Test  ") "test") "sanitize: trim whitespace")
(assert (= (M._sanitize-title "My--Title") "my-title") "sanitize: collapse dashes")
(assert (= (M._sanitize-title "CamelCase") "camelcase") "sanitize: lowercase")

;; Test generate-filename format
(let [filename (M.generate-filename "test")]
  (assert (filename:match "^%d+_%d+_test%.md$") "filename: format YYYYMMDD_HHMMSS_title.md"))

;; Test generate-template
(let [content (M.generate-template "Test Title")]
  (assert (content:match "^%-%-%-") "template: starts with frontmatter")
  (assert (content:match "tags: %[%]") "template: has empty tags")
  (assert (content:match "# Test Title") "template: has title heading"))

;; Test get-memo-info
(let [info (M.get-memo-info "/path/to/20260117_143052_my-memo.md")]
  (assert (= info.filename "20260117_143052_my-memo.md") "info: filename")
  (assert (= info.date "20260117_143052") "info: date")
  (assert (= info.title "my memo") "info: title with spaces"))

(print "memo_test.fnl: All tests passed")
