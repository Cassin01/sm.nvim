;;; sm/config_test.fnl - Tests for config

;; Setup Lua path for compiled modules
(set package.path (.. "./lua/?.lua;" package.path))

;; Mock vim BEFORE requiring modules
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

(local M (require :sm.config))

;; Test M.get auto-initializes config
(M.setup {})
(let [cfg (M.get)]
  (assert (not= cfg nil) "get: auto-initializes config")
  (assert (= cfg.date_format "%Y%m%d_%H%M%S") "get: has default date-format"))

;; Test get_memos_dir works
(M.setup {})
(let [dir (M.get_memos_dir)]
  (assert (not= dir nil) "get-memos-dir: returns value")
  (assert (dir:find "/memos$") "get-memos-dir: ends with /memos"))

;; Test get_state_file works
(M.setup {})
(let [file (M.get_state_file)]
  (assert (not= file nil) "get-state-file: returns value")
  (assert (file:find "/state%.json$") "get-state-file: ends with /state.json"))

;; Test M.setup merges user options
(M.setup {:date_format "%Y-%m-%d" :custom_opt "test"})
(let [cfg (M.get)]
  (assert (= cfg.date_format "%Y-%m-%d") "setup: overrides defaults")
  (assert (= cfg.custom_opt "test") "setup: adds custom options"))

;; Test custom memos_dir is respected
(M.setup {:memos_dir "/custom/memos"})
(assert (= (M.get_memos_dir) "/custom/memos") "get-memos-dir: respects custom path")

;; Test custom state_file is respected
(M.setup {:state_file "/custom/state.json"})
(assert (= (M.get_state_file) "/custom/state.json") "get-state-file: respects custom path")

(print "config_test.lua: All tests passed")
