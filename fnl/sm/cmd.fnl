;;; sm/cmd.fnl - User commands for sm.nvim

(import-macros {: la} :kaza.macros)
(local {: u-cmd} (require :kaza))

(u-cmd
  :SmOpen
  (la ((. (require :sm) :open-last)))
  {:desc "Open last edited memo"})

(u-cmd
  :SmNew
  (λ [opts]
    (let [sm (require :sm)
          title (if (and opts.args (> (length opts.args) 0))
                  opts.args
                  nil)]
      (sm.create title)))
  {:nargs "?"
   :desc "Create new memo"})

(u-cmd
  :SmList
  (la ((. (require :sm) :list)))
  {:desc "List all memos"})

(u-cmd
  :SmGrep
  (la ((. (require :sm) :grep)))
  {:desc "Search memo contents"})

(u-cmd
  :SmTags
  (la ((. (require :sm) :tags)))
  {:desc "Browse memos by tag"})

(u-cmd
  :SmTagSearch
  (λ [opts]
    ((. (require :sm) :search-by-tag) opts.args))
  {:nargs 1
   :complete (la ((. (require :sm) :list-all-tags)))
   :desc "Search memos by tag"})

(u-cmd
  :SmAddTag
  (λ [opts]
    (let [tag (if (and opts.args (> (length opts.args) 0))
                opts.args
                nil)]
      ((. (require :sm) :add-tag) tag)))
  {:nargs "?"
   :complete (la ((. (require :sm) :list-all-tags)))
   :desc "Add tag to current memo"})

(u-cmd
  :SmFollowLink
  (la ((. (require :sm) :follow-link)))
  {:desc "Follow wiki link under cursor"})

(u-cmd
  :SmInsertLink
  (la ((. (require :sm) :insert-link)))
  {:desc "Insert wiki link from picker"})
