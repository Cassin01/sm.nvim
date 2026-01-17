;;; sm/tags_test.fnl - Tests for tags

;; Setup path for standalone execution
(let [fennel (require :fennel)]
  (set fennel.path (.. "./fnl/?.fnl;" fennel.path)))

;; Mock dependencies BEFORE requiring modules
(when (not _G.vim)
  (set _G.vim {:tbl_deep_extend (fn [_ t1 t2]
                                  (let [result {}]
                                    (each [k v (pairs t1)] (tset result k v))
                                    (each [k v (pairs t2)] (tset result k v))
                                    result))}))
(tset package.loaded :kaza.file {:nvim-cache (fn [] "/tmp/test-nvim-cache")})

(local M (require :sm.tags))

;; Test parse-frontmatter with tags
(let [content "---\ntags: [work, ideas]\ncreated: 2026-01-17\n---\n# Test"
      result (M.parse-frontmatter content)]
  (assert (= (length result.tags) 2) "parse: tag count")
  (assert (= (. result.tags 1) "work") "parse: first tag")
  (assert (= (. result.tags 2) "ideas") "parse: second tag")
  (assert (= result.created "2026-01-17") "parse: created date"))

;; Test parse-frontmatter with empty tags
(let [content "---\ntags: []\ncreated: 2026-01-17\n---\n# Test"
      result (M.parse-frontmatter content)]
  (assert (= (length result.tags) 0) "parse: empty tags"))

;; Test parse-frontmatter without frontmatter
(let [result (M.parse-frontmatter "No frontmatter here")]
  (assert (= (length result.tags) 0) "parse: no frontmatter")
  (assert (= result.created nil) "parse: no created"))

;; Test parse-frontmatter with spaces in tags
(let [content "---\ntags: [ tag1 , tag2 , tag3 ]\n---\n"
      result (M.parse-frontmatter content)]
  (assert (= (length result.tags) 3) "parse: tags with spaces")
  (assert (= (. result.tags 1) "tag1") "parse: trimmed tag"))

(print "tags_test.fnl: All tests passed")
