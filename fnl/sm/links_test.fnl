;;; sm/links_test.fnl - Tests for links

;; Setup Lua path for compiled modules
(set package.path (.. "./lua/?.lua;" package.path))

;; Mock dependencies BEFORE requiring modules
(when (not _G.vim)
  (set _G.vim {:tbl_deep_extend (fn [_ t1 t2]
                                  (let [result {}]
                                    (each [k v (pairs t1)] (tset result k v))
                                    (each [k v (pairs t2)] (tset result k v))
                                    result))
               :startswith (fn [str prefix]
                             (= (str:sub 1 (length prefix)) prefix))}))
(tset package.loaded :kaza.file {:nvim-cache (fn [] "/tmp/test-nvim-cache")})

(local M (require :sm.links))

;; Test parse-link with valid links
(assert (= (M.parse-link "[[memo-name]]") "memo-name") "parse: simple link")
(assert (= (M.parse-link "[[20260117_test]]") "20260117_test") "parse: timestamp link")
(assert (= (M.parse-link "text [[link]] more") "link") "parse: link in text")
(assert (= (M.parse-link "[[my memo title]]") "my memo title") "parse: link with spaces")

;; Test parse-link with invalid/no links
(assert (= (M.parse-link "no link here") nil) "parse: no link")
(assert (= (M.parse-link "[single bracket]") nil) "parse: single brackets")
(assert (= (M.parse-link "[[]]") nil) "parse: empty link")
(assert (= (M.parse-link "[[unclosed") nil) "parse: unclosed link")

;; Test parse-link with multiple links (returns first)
(assert (= (M.parse-link "[[first]] and [[second]]") "first") "parse: multiple links")

(print "links_test.lua: All tests passed")
