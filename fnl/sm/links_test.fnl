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
               :fn {:stdpath (fn [which] "/tmp/test-nvim-cache")
                    :fnamemodify (fn [path modifier]
                                   (if (= modifier ":t:r")
                                     (let [filename (path:match "([^/]+)$")]
                                       (or (filename:match "(.+)%.md$") filename))
                                     (= modifier ":t")
                                     (path:match "([^/]+)$")
                                     path))}}))

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

;; Mock sm.memo and sm.config for find_memo_by_partial tests
(tset package.loaded :sm.memo
      {:list (fn []
               ["/tmp/memos/20260117_120000_meeting.md"
                "/tmp/memos/20260118_150000_important-meeting.md"
                "/tmp/memos/20260119_100000_project-meeting-notes.md"])})

(tset package.loaded :sm.config
      {:get_memos_dir (fn [] "/tmp/memos")})

;; Reload M to pick up mocked modules
(tset package.loaded :sm.links nil)
(local M (require :sm.links))

;; Test exact match is preferred over partial match
(let [result (M.find_memo_by_partial "20260117_120000_meeting")]
  (assert (= result "/tmp/memos/20260117_120000_meeting.md") "find_memo: exact match preferred"))

;; Test case-insensitive exact match
(let [result (M.find_memo_by_partial "20260117_120000_MEETING")]
  (assert (= result "/tmp/memos/20260117_120000_meeting.md") "find_memo: case-insensitive exact match"))

;; Test partial match when no exact match exists
(let [result (M.find_memo_by_partial "important")]
  (assert (= result "/tmp/memos/20260118_150000_important-meeting.md") "find_memo: partial match works"))

;; Test that partial match returns a result
(let [result (M.find_memo_by_partial "meeting")]
  (assert (~= result nil) "find_memo: partial match returns result"))

(print "links_test.lua: All tests passed")
