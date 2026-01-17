;;; sm/links_test.fnl - Tests for links

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
               :startswith (fn [str prefix]
                             (= (str:sub 1 (length prefix)) prefix))
               :fn {:stdpath (fn [which] "/tmp/test-nvim-cache")}}))

(local M (require :sm.links))

;; Test parse_link with valid links
(assert (= (M.parse_link "[[memo-name]]") "memo-name") "parse: simple link")
(assert (= (M.parse_link "[[20260117_test]]") "20260117_test") "parse: timestamp link")
(assert (= (M.parse_link "text [[link]] more") "link") "parse: link in text")
(assert (= (M.parse_link "[[my memo title]]") "my memo title") "parse: link with spaces")

;; Test parse_link with invalid/no links
(assert (= (M.parse_link "no link here") nil) "parse: no link")
(assert (= (M.parse_link "[single bracket]") nil) "parse: single brackets")
(assert (= (M.parse_link "[[]]") nil) "parse: empty link")
(assert (= (M.parse_link "[[unclosed") nil) "parse: unclosed link")

;; Test parse_link with multiple links (returns first)
(assert (= (M.parse_link "[[first]] and [[second]]") "first") "parse: multiple links")

(print "links_test.lua: All tests passed")
