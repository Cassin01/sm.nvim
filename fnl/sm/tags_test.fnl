;;; sm/tags_test.fnl - Tests for tags

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
               :fn {:stdpath (fn [which] "/tmp/test-nvim-cache")}}))

(local M (require :sm.tags))

;; Test parse_frontmatter with tags
(let [content "---\ntags: [work, ideas]\ncreated: 2026-01-17\n---\n# Test"
      result (M.parse_frontmatter content)]
  (assert (= (length result.tags) 2) "parse: tag count")
  (assert (= (. result.tags 1) "work") "parse: first tag")
  (assert (= (. result.tags 2) "ideas") "parse: second tag")
  (assert (= result.created "2026-01-17") "parse: created date"))

;; Test parse_frontmatter with empty tags
(let [content "---\ntags: []\ncreated: 2026-01-17\n---\n# Test"
      result (M.parse_frontmatter content)]
  (assert (= (length result.tags) 0) "parse: empty tags"))

;; Test parse_frontmatter without frontmatter
(let [result (M.parse_frontmatter "No frontmatter here")]
  (assert (= (length result.tags) 0) "parse: no frontmatter")
  (assert (= result.created nil) "parse: no created"))

;; Test parse_frontmatter with spaces in tags
(let [content "---\ntags: [ tag1 , tag2 , tag3 ]\n---\n"
      result (M.parse_frontmatter content)]
  (assert (= (length result.tags) 3) "parse: tags with spaces")
  (assert (= (. result.tags 1) "tag1") "parse: trimmed tag"))

(print "tags_test.lua: All tests passed")
