;;; sm/telescope.fnl - Telescope pickers for sm.nvim

(local M {})
(local config (require :sm.config))

(fn M.memo-picker []
  "Telescope picker for all memos"
  (let [pickers (require :telescope.pickers)
        finders (require :telescope.finders)
        conf (. (require :telescope.config) :values)
        actions (require :telescope.actions)
        action-state (require :telescope.actions.state)
        previewers (require :telescope.previewers)
        memo (require :sm.memo)
        tags-mod (require :sm.tags)
        files (memo.list)
        entries []]
    (each [_ filepath (ipairs files)]
      (let [info (memo.get-memo-info filepath)
            tags (tags-mod.get-memo-tags filepath)
            tags-str (if (> (length tags) 0)
                       (.. " [" (table.concat tags ", ") "]")
                       "")]
        (table.insert entries
          {:value filepath
           :display (.. info.date " | " info.title tags-str)
           :ordinal (.. info.date " " info.title " " (table.concat tags " "))})))
    (: (pickers.new {}
         {:prompt_title "Memos"
          :finder (finders.new_table
                    {:results entries
                     :entry_maker (fn [entry] entry)})
          :sorter (conf.generic_sorter {})
          :previewer (previewers.new_buffer_previewer
                       {:title "Memo Preview"
                        :define_preview (fn [self entry bufnr]
                          (conf.buffer_previewer_maker entry.value bufnr {}))})
          :attach_mappings (fn [prompt_bufnr map]
            (actions.select_default:replace
              (fn []
                (actions.close prompt_bufnr)
                (let [selection (action-state.get_selected_entry)]
                  (memo.open selection.value))))
            true)})
       :find)))

(fn M.memo-grep []
  "Live grep through memo contents"
  (let [builtin (require :telescope.builtin)]
    (builtin.live_grep
      {:cwd (config.get-memos-dir)
       :prompt_title "Grep Memos"
       :glob_pattern "*.md"})))

(fn M.tag-picker []
  "Telescope picker for tags, shows tag with memo count"
  (let [pickers (require :telescope.pickers)
        finders (require :telescope.finders)
        conf (. (require :telescope.config) :values)
        actions (require :telescope.actions)
        action-state (require :telescope.actions.state)
        tags-mod (require :sm.tags)
        tags-with-counts (tags-mod.get-tags-with-counts)]
    (: (pickers.new {}
         {:prompt_title "Tags"
          :finder (finders.new_table
                    {:results tags-with-counts
                     :entry_maker (fn [entry]
                       {:value entry.tag
                        :display (string.format "%-20s (%d memos)" entry.tag entry.count)
                        :ordinal entry.tag})})
          :sorter (conf.generic_sorter {})
          :attach_mappings (fn [prompt_bufnr map]
            (actions.select_default:replace
              (fn []
                (actions.close prompt_bufnr)
                (let [selection (action-state.get_selected_entry)]
                  (M.memos-by-tag-picker selection.value))))
            true)})
       :find)))

(fn M.memos-by-tag-picker [tag]
  "Telescope picker for memos with specific tag"
  (let [pickers (require :telescope.pickers)
        finders (require :telescope.finders)
        conf (. (require :telescope.config) :values)
        actions (require :telescope.actions)
        action-state (require :telescope.actions.state)
        previewers (require :telescope.previewers)
        memo (require :sm.memo)
        tags-mod (require :sm.tags)
        files (tags-mod.get-memos-by-tag tag)
        entries []]
    (each [_ filepath (ipairs files)]
      (let [info (memo.get-memo-info filepath)]
        (table.insert entries
          {:value filepath
           :display (.. info.date " | " info.title)
           :ordinal (.. info.date " " info.title)})))
    (: (pickers.new {}
         {:prompt_title (.. "Memos tagged: " tag)
          :finder (finders.new_table
                    {:results entries
                     :entry_maker (fn [entry] entry)})
          :sorter (conf.generic_sorter {})
          :previewer (previewers.new_buffer_previewer
                       {:title "Memo Preview"
                        :define_preview (fn [self entry bufnr]
                          (conf.buffer_previewer_maker entry.value bufnr {}))})
          :attach_mappings (fn [prompt_bufnr map]
            (actions.select_default:replace
              (fn []
                (actions.close prompt_bufnr)
                (let [selection (action-state.get_selected_entry)]
                  (memo.open selection.value))))
            true)})
       :find)))

M
