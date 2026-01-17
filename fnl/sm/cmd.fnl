;;; sm/cmd.fnl - User commands for sm.nvim

(local M {})

(fn M.setup []
  "Register all sm.nvim commands"

  (vim.api.nvim_create_user_command :SmOpen
    (fn [] ((. (require :sm) :open_last)))
    {:desc "Open last edited memo"})

  (vim.api.nvim_create_user_command :SmNew
    (fn [opts]
      (let [sm (require :sm)
            title (when (and opts.args (> (length opts.args) 0)) opts.args)]
        (sm.create title)))
    {:nargs "?" :desc "Create new memo"})

  (vim.api.nvim_create_user_command :SmAddTag
    (fn [opts]
      (let [tag (when (and opts.args (> (length opts.args) 0)) opts.args)]
        ((. (require :sm) :add_tag) tag)))
    {:nargs "?"
     :complete (fn [] ((. (require :sm) :list_all_tags)))
     :desc "Add tag to current memo"})

  (vim.api.nvim_create_user_command :SmFollowLink
    (fn [] ((. (require :sm) :follow_link)))
    {:desc "Follow wiki link under cursor"}))

M
