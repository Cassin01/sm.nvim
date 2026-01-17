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

;;; Public API - Link operations

(fn M.follow-link []
  "Follow wiki link under cursor"
  (let [links (require :sm.links)]
    (links.follow-link)))

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
