;;; sm/links.fnl - Wiki-style link handling for sm.nvim

(local M {})
(local config (require :sm.config))

(fn M.parse_link [text]
  "Extract memo name from [[memo-name]] pattern
   Returns the link text or nil if not a valid link"
  (text:match "%[%[([^%]]+)%]%]"))

(fn M.get_link_under_cursor []
  "Get wiki link under cursor if any"
  (let [line (vim.api.nvim_get_current_line)
        col (vim.fn.col ".")
        before (line:sub 1 col)
        after (line:sub col)]
    (let [start_pos (before:match ".*()%[%[")]
      (when start_pos
        (let [full_from_start (line:sub start_pos)
              link (full_from_start:match "%[%[([^%]]+)%]%]")]
          link)))))

(fn M.find_memo_by_partial [name]
  "Find memo file that matches partial name
   Tries exact match first, then partial matches"
  (let [memo (require :sm.memo)
        files (memo.list)
        dir (config.get_memos_dir)
        name_lower (name:lower)]
    (var result nil)
    (each [_ filepath (ipairs files) &until result]
      (let [filename (vim.fn.fnamemodify filepath ":t:r")
            filename_lower (filename:lower)]
        (when (or (= filename_lower name_lower)
                  (filename_lower:find name_lower 1 true))
          (set result filepath))))
    result))

(fn M.follow_link []
  "Follow wiki link under cursor"
  (let [link_text (M.get_link_under_cursor)]
    (if link_text
      (let [target (M.find_memo_by_partial link_text)]
        (if target
          (let [memo (require :sm.memo)]
            (memo.open target))
          (do
            (vim.notify
              (.. "Memo not found: " link_text ". Create new?")
              vim.log.levels.INFO)
            (vim.ui.select [:Yes :No] {:prompt "Create new memo?"}
              (fn [choice]
                (when (= choice :Yes)
                  (let [memo (require :sm.memo)]
                    (memo.create link_text))))))))
      (vim.notify "No wiki link under cursor" vim.log.levels.WARN))))

(fn M.create_link_from_selection []
  "Create [[link]] from visual selection"
  (let [start_pos (vim.fn.getpos "'<")
        end_pos (vim.fn.getpos "'>")
        lines (vim.api.nvim_buf_get_text 0
                (- (. start_pos 2) 1)
                (- (. start_pos 3) 1)
                (- (. end_pos 2) 1)
                (. end_pos 3)
                {})]
    (when (> (length lines) 0)
      (let [text (table.concat lines " ")
            link (.. "[[" text "]]")]
        (vim.api.nvim_buf_set_text 0
          (- (. start_pos 2) 1)
          (- (. start_pos 3) 1)
          (- (. end_pos 2) 1)
          (. end_pos 3)
          [link])))))

(fn M.setup_buffer_mappings []
  "Setup buffer-local mappings for wiki links in memo buffers"
  (let [buf (vim.api.nvim_get_current_buf)
        filepath (vim.api.nvim_buf_get_name buf)
        memos_dir (config.get_memos_dir)]
    (when (vim.startswith filepath memos_dir)
      (vim.keymap.set :n :gf
        (fn [] (M.follow_link))
        {:buffer buf :desc "Follow wiki link"}))))

M
