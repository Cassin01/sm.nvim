;;; sm/cmd.fnl - User commands for sm.nvim

(local M {})

(fn M.setup []
  "Register all sm.nvim commands"

  (vim.api.nvim_create_user_command :SmOpen
    (fn [] ((. (require :sm) :open-last)))
    {:desc "Open last edited memo"})

  (vim.api.nvim_create_user_command :SmNew
    (fn [opts]
      (let [sm (require :sm)
            title (when (and opts.args (> (length opts.args) 0)) opts.args)]
        (sm.create title)))
    {:nargs "?" :desc "Create new memo"})

  (vim.api.nvim_create_user_command :SmList
    (fn [] ((. (require :sm) :list)))
    {:desc "List all memos"})

  (vim.api.nvim_create_user_command :SmGrep
    (fn [] ((. (require :sm) :grep)))
    {:desc "Search memo contents"})

  (vim.api.nvim_create_user_command :SmTags
    (fn [] ((. (require :sm) :tags)))
    {:desc "Browse memos by tag"})

  (vim.api.nvim_create_user_command :SmTagSearch
    (fn [opts] ((. (require :sm) :search-by-tag) opts.args))
    {:nargs 1
     :complete (fn [] ((. (require :sm) :list-all-tags)))
     :desc "Search memos by tag"})

  (vim.api.nvim_create_user_command :SmAddTag
    (fn [opts]
      (let [tag (when (and opts.args (> (length opts.args) 0)) opts.args)]
        ((. (require :sm) :add-tag) tag)))
    {:nargs "?"
     :complete (fn [] ((. (require :sm) :list-all-tags)))
     :desc "Add tag to current memo"})

  (vim.api.nvim_create_user_command :SmFollowLink
    (fn [] ((. (require :sm) :follow-link)))
    {:desc "Follow wiki link under cursor"})

  (vim.api.nvim_create_user_command :SmInsertLink
    (fn [] ((. (require :sm) :insert-link)))
    {:desc "Insert wiki link from picker"}))

M
