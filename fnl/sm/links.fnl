;;; sm/links.fnl - Wiki-style link handling for sm.nvim

(local M {})
(local config (require :sm.config))

(fn M.parse-link [text]
  "Extract memo name from [[memo-name]] pattern
   Returns the link text or nil if not a valid link"
  (text:match "%[%[([^%]]+)%]%]"))

(fn M.get-link-under-cursor []
  "Get wiki link under cursor if any"
  (let [line (vim.api.nvim_get_current_line)
        col (vim.fn.col ".")
        before (line:sub 1 col)
        after (line:sub col)]
    (let [start-pos (before:match ".*()%[%[")]
      (when start-pos
        (let [full-from-start (line:sub start-pos)
              link (full-from-start:match "%[%[([^%]]+)%]%]")]
          link)))))

(fn M.find-memo-by-partial [name]
  "Find memo file that matches partial name
   Tries exact match first, then partial matches"
  (let [memo (require :sm.memo)
        files (memo.list)
        dir (config.get-memos-dir)
        name-lower (name:lower)]
    (var result nil)
    (each [_ filepath (ipairs files) &until result]
      (let [filename (vim.fn.fnamemodify filepath ":t:r")
            filename-lower (filename:lower)]
        (when (or (= filename-lower name-lower)
                  (filename-lower:find name-lower 1 true))
          (set result filepath))))
    result))

(fn M.follow-link []
  "Follow wiki link under cursor"
  (let [link-text (M.get-link-under-cursor)]
    (if link-text
      (let [target (M.find-memo-by-partial link-text)]
        (if target
          (let [memo (require :sm.memo)]
            (memo.open target))
          (do
            (vim.notify
              (.. "Memo not found: " link-text ". Create new?")
              vim.log.levels.INFO)
            (vim.ui.select [:Yes :No] {:prompt "Create new memo?"}
              (fn [choice]
                (when (= choice :Yes)
                  (let [memo (require :sm.memo)]
                    (memo.create link-text))))))))
      (vim.notify "No wiki link under cursor" vim.log.levels.WARN))))

(fn M.create-link-from-selection []
  "Create [[link]] from visual selection"
  (let [start-pos (vim.fn.getpos "'<")
        end-pos (vim.fn.getpos "'>")
        lines (vim.api.nvim_buf_get_text 0
                (- (. start-pos 2) 1)
                (- (. start-pos 3) 1)
                (- (. end-pos 2) 1)
                (. end-pos 3)
                {})]
    (when (> (length lines) 0)
      (let [text (table.concat lines " ")
            link (.. "[[" text "]]")]
        (vim.api.nvim_buf_set_text 0
          (- (. start-pos 2) 1)
          (- (. start-pos 3) 1)
          (- (. end-pos 2) 1)
          (. end-pos 3)
          [link])))))

(fn M.insert-link []
  "Insert a wiki link by selecting from existing memos"
  (let [pickers (require :telescope.pickers)
        finders (require :telescope.finders)
        conf (. (require :telescope.config) :values)
        actions (require :telescope.actions)
        action-state (require :telescope.actions.state)
        memo (require :sm.memo)
        files (memo.list)
        entries []]
    (each [_ filepath (ipairs files)]
      (let [info (memo.get-memo-info filepath)
            filename (vim.fn.fnamemodify filepath ":t:r")]
        (table.insert entries
          {:value filename
           :display (.. info.date " | " info.title)
           :ordinal (.. info.date " " info.title)})))
    (: (pickers.new {}
         {:prompt_title "Insert Link"
          :finder (finders.new_table
                    {:results entries
                     :entry_maker (fn [entry] entry)})
          :sorter (conf.generic_sorter {})
          :attach_mappings (fn [prompt_bufnr map]
            (actions.select_default:replace
              (fn []
                (actions.close prompt_bufnr)
                (let [selection (action-state.get_selected_entry)
                      link (.. "[[" selection.value "]]")]
                  (vim.api.nvim_put [link] :c true true))))
            true)})
       :find)))

(fn M.setup-buffer-mappings []
  "Setup buffer-local mappings for wiki links in memo buffers"
  (let [buf (vim.api.nvim_get_current_buf)
        filepath (vim.api.nvim_buf_get_name buf)
        memos-dir (config.get-memos-dir)]
    (when (vim.startswith filepath memos-dir)
      (vim.keymap.set :n :gf
        (fn [] (M.follow-link))
        {:buffer buf :desc "Follow wiki link"}))))

M
