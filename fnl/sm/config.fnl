;;; sm/config.fnl - Configuration management for sm.nvim

(local M {})

(local defaults
  {:memos_dir nil  ; will be set to ~/.cache/nvim/sm/memos
   :state_file nil ; will be set to ~/.cache/nvim/sm/state.json
   :date_format "%Y%m%d_%H%M%S"
   :auto_tag_git_repo false ; optional: add git repo name as tag when creating memo
   :copilot_integration false  ; opt-in: attach copilot to memo buffers
   :split_height 15  ; height for horizontal split window
   :template ["---"
              "tags: [%tags%]"
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
(var setup_called false)

(fn M.get_base_dir []
  "Get base sm directory (~/.cache/nvim/sm)"
  (.. (vim.fn.stdpath :cache) "/sm"))

(fn M.get_memos_dir []
  "Get memos directory path"
  (let [cfg (M.get)]
    (if cfg.memos_dir
      cfg.memos_dir
      (.. (M.get_base_dir) "/memos"))))

(fn M.get_state_file []
  "Get state file path"
  (let [cfg (M.get)]
    (if cfg.state_file
      cfg.state_file
      (.. (M.get_base_dir) "/state.json"))))

(fn M.setup [?opts]
  "Initialize configuration with optional user overrides"
  (if setup_called
      (do
        (vim.notify "sm.nvim: setup() called multiple times, ignoring subsequent call" vim.log.levels.WARN)
        config)
      (do
        (set config (vim.tbl_deep_extend :force defaults (or ?opts {})))
        (set setup_called true)
        config)))

(fn M.get []
  "Get current configuration (returns a deep copy), initialize with defaults if needed"
  (when (= config nil)
    (M.setup {}))
  (vim.deepcopy config))

(fn M.reset []
  "Reset configuration to nil (for testing/reloading)"
  (set config nil)
  (set setup_called false))

;; Export for testing
(tset M :_reset M.reset)

M
