;;; sm/config.fnl - Configuration management for sm.nvim

(local M {})

(local defaults
  {:memos-dir nil  ; will be set to ~/.cache/nvim/sm/memos
   :state-file nil ; will be set to ~/.cache/nvim/sm/state.json
   :date-format "%Y%m%d_%H%M%S"
   :template ["---"
              "tags: []"
              "created: %date%"
              "---"
              ""
              "# %title%"
              ""]
   :window {:width 80
            :height 30
            :border :rounded
            :style :minimal}})

(var config nil)

(fn M.get-base-dir []
  "Get base sm directory (~/.cache/nvim/sm)"
  (let [{: nvim-cache} (require :kaza.file)]
    (.. (nvim-cache) "/sm")))

(fn M.get-memos-dir []
  "Get memos directory path"
  (let [cfg (M.get)]
    (if cfg.memos-dir
      cfg.memos-dir
      (.. (M.get-base-dir) "/memos"))))

(fn M.get-state-file []
  "Get state file path"
  (let [cfg (M.get)]
    (if cfg.state-file
      cfg.state-file
      (.. (M.get-base-dir) "/state.json"))))

(fn M.setup [?opts]
  "Initialize configuration with optional user overrides"
  (set config (vim.tbl_deep_extend :force defaults (or ?opts {})))
  config)

(fn M.get []
  "Get current configuration, initialize with defaults if needed"
  (when (= config nil)
    (M.setup {}))
  config)

;;; test (run with: nvim --headless -c "lua require('sm.config')" -c "qa")
;;; These tests run inside Neovim since they depend on vim.tbl_deep_extend

(local (method-name) ...)
(when (= method-name nil)
  ;; Mock kaza.file for standalone testing
  (when (not _G.vim)
    (set _G.vim {:tbl_deep_extend (fn [_ t1 t2]
                                    (let [result {}]
                                      (each [k v (pairs t1)] (tset result k v))
                                      (each [k v (pairs t2)] (tset result k v))
                                      result))}))
  (when (not package.loaded.kaza.file)
    (tset package.loaded :kaza.file {:nvim-cache (fn [] "/tmp/test-nvim-cache")}))

  ;; Reset config before tests
  (set config nil)

  ;; Test M.get auto-initializes config
  (let [cfg (M.get)]
    (assert (not= cfg nil) "get: auto-initializes config")
    (assert (= cfg.date-format "%Y%m%d_%H%M%S") "get: has default date-format"))

  ;; Test get-memos-dir works without prior setup (the bug we fixed)
  (set config nil)
  (let [dir (M.get-memos-dir)]
    (assert (not= dir nil) "get-memos-dir: works without prior setup")
    (assert (dir:find "/memos$") "get-memos-dir: ends with /memos"))

  ;; Test get-state-file works without prior setup (the bug we fixed)
  (set config nil)
  (let [file (M.get-state-file)]
    (assert (not= file nil) "get-state-file: works without prior setup")
    (assert (file:find "/state%.json$") "get-state-file: ends with /state.json"))

  ;; Test M.setup merges user options
  (set config nil)
  (M.setup {:date-format "%Y-%m-%d" :custom-opt "test"})
  (let [cfg (M.get)]
    (assert (= cfg.date-format "%Y-%m-%d") "setup: overrides defaults")
    (assert (= cfg.custom-opt "test") "setup: adds custom options"))

  ;; Test custom memos-dir is respected
  (set config nil)
  (M.setup {:memos-dir "/custom/memos"})
  (assert (= (M.get-memos-dir) "/custom/memos") "get-memos-dir: respects custom path")

  ;; Test custom state-file is respected
  (set config nil)
  (M.setup {:state-file "/custom/state.json"})
  (assert (= (M.get-state-file) "/custom/state.json") "get-state-file: respects custom path")

  (print "config.fnl: All tests passed"))

M
