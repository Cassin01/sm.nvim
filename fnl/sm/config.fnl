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

M
