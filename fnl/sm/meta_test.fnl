;;; sm/meta_test.fnl - Tests for The Recursive Self-Documentation Paradox

;; Setup Lua path for compiled modules
(set package.path (.. "./lua/?.lua;" package.path))

;; Mock vim API BEFORE requiring modules
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
                    :fnamemodify (fn [path modifier] path)}
               :api {:nvim_create_buf (fn [listed scratch] 1)
                     :nvim_buf_set_lines (fn [buf start end strict lines] nil)
                     :nvim_buf_set_option (fn [buf opt val] nil)
                     :nvim_open_win (fn [buf enter opts] 1)
                     :nvim_buf_set_keymap (fn [buf mode lhs rhs opts] nil)
                     :nvim_win_close (fn [win force] nil)}
               :o {:columns 120 :lines 40}}))

;; Mock memo module
(tset package.loaded :sm.memo
      {:list (fn []
               ["/tmp/memos/20260101_120000_first-memo.md"
                "/tmp/memos/20260102_130000_second-memo.md"
                "/tmp/memos/20260103_140000_third-memo.md"])})

;; Mock tags module
(tset package.loaded :sm.tags
      {:get_tags_with_counts (fn []
                               [{:tag "todo" :count 5}
                                {:tag "work" :count 3}
                                {:tag "ideas" :count 1}])
       :list_all_tags (fn [] ["ideas" "todo" "work"])})

;; Mock state module
(tset package.loaded :sm.state
      {:get_recent (fn [?limit] ["first.md" "second.md"])
       :get_last_edited (fn [] "/tmp/memos/20260103_140000_third-memo.md")})

;; Mock config module
(tset package.loaded :sm.config
      {:get (fn []
              {:window {:width 80 :height 30 :border "rounded" :style "minimal"}})
       :get_memos_dir (fn [] "/tmp/memos")})

;; Require module under test
(local M (require :sm.meta))

;; Test get_statistics returns expected keys
(let [stats (M.get_statistics)]
  (assert (= (type stats) "table") "get_statistics: returns table")
  (assert (= stats.total_memos 3) "get_statistics: total_memos count")
  (assert (= stats.total_tags 3) "get_statistics: total_tags count")
  (assert (= stats.recent_count 2) "get_statistics: recent_count")
  (assert (= (type stats.top_tags) "table") "get_statistics: top_tags is table")
  (assert (= (length stats.top_tags) 3) "get_statistics: top_tags count")
  (assert (= (. stats.top_tags 1 :tag) "todo") "get_statistics: top tag is todo"))

;; Test get_behavior_analysis returns table of strings
(let [stats {:total_memos 150 :total_tags 5 :recent_count 20 :top_tags [{:tag "todo" :count 50}]}
      analysis (M.get_behavior_analysis stats)]
  (assert (= (type analysis) "table") "get_behavior_analysis: returns table")
  (assert (> (length analysis) 0) "get_behavior_analysis: has observations"))

;; Test get_behavior_analysis with few memos
(let [stats {:total_memos 2 :total_tags 1 :recent_count 2 :top_tags [{:tag "test" :count 1}]}
      analysis (M.get_behavior_analysis stats)]
  (assert (= (type analysis) "table") "get_behavior_analysis: handles few memos"))

;; Test generate_meta_content returns lines
(let [lines (M.generate_meta_content)]
  (assert (= (type lines) "table") "generate_meta_content: returns table")
  (assert (> (length lines) 0) "generate_meta_content: has content")
  (assert (= (. lines 1) "# The Memo Knows") "generate_meta_content: has title"))

;; Test content includes statistics
(let [lines (M.generate_meta_content)
      content (table.concat lines "\n")]
  (assert (content:find "Total memos") "generate_meta_content: includes total memos")
  (assert (content:find "3") "generate_meta_content: shows memo count")
  (assert (content:find "todo") "generate_meta_content: includes top tag"))

(print "meta_test.lua: All tests passed")
