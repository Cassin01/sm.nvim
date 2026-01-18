;;; sm/init_test.fnl - Tests for init (public API)

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
               :notify (fn [msg level] nil)
               :log {:levels {:DEBUG 1 :INFO 2 :WARN 3 :ERROR 4}}
               :api {:nvim_create_augroup (fn [name opts] 1)
                     :nvim_create_autocmd (fn [events opts] nil)}
               :fn {:stdpath (fn [which] "/tmp/test-nvim-cache")}}))

;; Mock sm.cmd to avoid its dependencies
(tset package.loaded :sm.cmd
      {:setup (fn [] nil)})

;; Mock sm.links to avoid its dependencies
(tset package.loaded :sm.links
      {:setup_buffer_mappings (fn [] nil)})

(local M (require :sm.init))

;; Test autocmd_pattern returns correct pattern
(let [pattern (M.autocmd_pattern)]
  (assert (not= pattern nil) "autocmd_pattern: returns value")
  (assert (pattern:find "/%*%.md$") "autocmd_pattern: ends with /*.md"))

;; Test autocmd_pattern includes memos directory
(let [pattern (M.autocmd_pattern)]
  (assert (pattern:find "/memos/") "autocmd_pattern: includes memos directory"))

(print "init_test.lua: All tests passed")
