;;; sm/init.fnl - Public API for sm.nvim (Simple Memo)

(local M {})

(fn M.setup [?opts]
  "Initialize sm.nvim with optional configuration"
  (let [config (require :sm.config)
        cmd (require :sm.cmd)]
    (config.setup ?opts)
    (cmd.setup)
    (M.setup-autocmds)))

(fn M.setup-autocmds []
  "Setup autocommands for sm.nvim"
  (let [group (vim.api.nvim_create_augroup :sm_nvim {:clear true})
        config (require :sm.config)]
    (vim.api.nvim_create_autocmd [:BufEnter]
      {:group group
       :pattern (.. (config.get-memos-dir) "/*.md")
       :callback (fn []
                   (let [links (require :sm.links)]
                     (links.setup-buffer-mappings)))})))

;;; Public API - Memo operations

(fn M.create [?title]
  "Create a new memo"
  (let [memo (require :sm.memo)]
    (memo.create ?title)))

(fn M.open-last []
  "Open the last edited memo"
  (let [memo (require :sm.memo)]
    (memo.open-last)))

(fn M.list []
  "List all memos - use sm.api with your preferred picker"
  (vim.notify
    "sm.nvim: Use require('sm.api').get_memos() with your preferred picker."
    vim.log.levels.WARN))

(fn M.grep []
  "Search memo contents - use grep in memos directory"
  (let [config (require :sm.config)]
    (vim.notify
      (.. "sm.nvim: Use grep in: " (config.get-memos-dir))
      vim.log.levels.WARN)))

(fn M.tags []
  "Browse memos by tag - use sm.api with your preferred picker"
  (vim.notify
    "sm.nvim: Use require('sm.api').get_tags() with your preferred picker."
    vim.log.levels.WARN))

(fn M.search-by-tag [tag]
  "Search memos with specific tag - use sm.api with your preferred picker"
  (vim.notify
    "sm.nvim: Use require('sm.api').get_memos_by_tag(tag) with your preferred picker."
    vim.log.levels.WARN))

;;; Public API - Link operations

(fn M.follow-link []
  "Follow wiki link under cursor"
  (let [links (require :sm.links)]
    (links.follow-link)))

(fn M.insert-link []
  "Insert a wiki link - use sm.api with your preferred picker"
  (vim.notify
    "sm.nvim: Use require('sm.api').get_memos_for_link() with your preferred picker."
    vim.log.levels.WARN))

;;; Public API - Tag operations

(fn M.list-all-tags []
  "Get list of all tags (for command completion)"
  (let [tags (require :sm.tags)]
    (tags.list-all-tags)))

(fn M.add-tag [?tag]
  "Add tag to current memo"
  (let [tags (require :sm.tags)
        filepath (vim.api.nvim_buf_get_name 0)]
    (if ?tag
      (tags.add-tag-to-memo filepath ?tag)
      (vim.ui.input {:prompt "Tag to add: "}
        (fn [input]
          (when (and input (> (length input) 0))
            (tags.add-tag-to-memo filepath input)
            (vim.notify (.. "Added tag: " input) vim.log.levels.INFO)))))))

M
