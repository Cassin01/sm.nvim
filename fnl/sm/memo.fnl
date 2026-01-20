;;; sm/memo.fnl - Core memo operations for sm.nvim

(local M {})
(local config (require :sm.config))
(local state (require :sm.state))

(fn ensure_memos_dir []
  "Create memos directory if it doesn't exist"
  (let [dir (config.get_memos_dir)]
    (when (= (vim.fn.isdirectory dir) 0)
      (vim.fn.mkdir dir :p))
    dir))

(fn sanitize_title [title]
  "Convert title to safe filename component"
  (-> title
      (: :lower)
      (: :gsub "[%s%c!\"#$%%&'()*+,./:;<=>?@%[\\%]^`{|}~]+" "-")
      (: :gsub "^%-+" "")
      (: :gsub "%-+$" "")
      (: :gsub "%-%-+" "-")))

(fn M.generate_filename [title]
  "Generate filename: YYYYMMDD_HHMMSS_{sanitized-title}.md"
  (let [cfg (config.get)
        date (os.date cfg.date_format)
        safe_title (sanitize_title title)]
    (.. date "_" safe_title ".md")))

(fn M.generate_template [title ?initial-tags]
  "Generate memo content from template.
   ?initial-tags: optional list of tags to include
   Supports %tags% placeholder (preferred) and legacy tags: [] format"
  (let [cfg (config.get)
        date_str (os.date "%Y-%m-%dT%H:%M:%S")
        tags (or ?initial-tags [])
        tags_str (table.concat tags ", ")
        lines []]
    (each [_ line (ipairs cfg.template)]
      (local processed (-> line
                          (: :gsub "%%date%%" date_str)
                          (: :gsub "%%title%%" title)
                          (: :gsub "%%tags%%" tags_str)
                          ;; Backward compat: legacy "tags: []" templates (replace once)
                          (: :gsub "tags: %[%]" (.. "tags: [" tags_str "]") 1)))
      (table.insert lines processed))
    (table.concat lines "\n")))

(fn M.get_filepath [filename]
  "Get full path for a memo filename"
  (.. (config.get_memos_dir) "/" filename))

(fn create_centered_input [prompt callback]
  "Create centered floating input window"
  (let [width 50
        height 1
        row (math.max 0 (math.floor (/ (- vim.o.lines height) 2)))
        col (math.max 0 (math.floor (/ (- vim.o.columns width) 2)))
        buf (vim.api.nvim_create_buf false true)
        (ok win) (pcall vim.api.nvim_open_win buf true
                   {:relative :editor
                    :width width
                    :height height
                    :row row
                    :col col
                    :style :minimal
                    :border :rounded
                    :title (.. " " prompt " ")
                    :title_pos :center})]
    (if (not ok)
      (do
        (when (vim.api.nvim_buf_is_valid buf)
          (vim.api.nvim_buf_delete buf {:force true}))
        (vim.notify (.. "Failed to create memo input window: " (or win "unknown error")) vim.log.levels.ERROR))
      (do
        (fn close_input []
          (when (vim.api.nvim_win_is_valid win)
            (vim.api.nvim_win_close win true))
          (when (vim.api.nvim_buf_is_valid buf)
            (vim.api.nvim_buf_delete buf {:force true})))
        (fn submit []
          (let [lines (vim.api.nvim_buf_get_lines buf 0 1 false)
                text (or (. lines 1) "")]
            (close_input)
            (when (> (length text) 0)
              (callback text))))
        (vim.keymap.set :i :<CR> submit {:buffer buf :noremap true})
        (vim.keymap.set :n :<CR> submit {:buffer buf :noremap true})
        (vim.keymap.set :i :<Esc> close_input {:buffer buf :noremap true})
        (vim.keymap.set :n :<Esc> close_input {:buffer buf :noremap true})
        (vim.keymap.set :n :q close_input {:buffer buf :noremap true})
        (vim.cmd :startinsert)))))

(fn get_initial_tags []
  "Build list of initial tags based on configuration"
  (let [cfg (config.get)
        tags []]
    (when cfg.auto_tag_git_repo
      (let [git (require :sm.git)
            repo_tag (git.get_repo_tag)]
        (when repo_tag
          (table.insert tags repo_tag))))
    tags))

(fn try_attach_copilot [attempts]
  "Try to attach copilot if enabled and available (with exponential backoff)"
  (let [cfg (config.get)]
    (when cfg.copilot_integration
      (let [(copilot_ok copilot) (pcall require :copilot.command)]
        (when copilot_ok
          (let [max_attempts 3
                delay (* attempts 100)]  ; 100ms, 200ms, 300ms
            (vim.defer_fn
              (fn []
                (let [(ok err) (pcall #(copilot.attach {:force true}))]
                  (when (and (not ok) (< attempts max_attempts))
                    (try_attach_copilot (+ attempts 1)))))
              delay)))))))

(fn goto_last_line []
  "Move cursor to the last line of current buffer"
  (let [last_line (vim.api.nvim_buf_line_count 0)]
    (vim.api.nvim_win_set_cursor 0 [last_line 0])))

(fn M.open_in_split [filepath]
  "Open file in horizontal split at bottom"
  (let [buf (vim.fn.bufadd filepath)]
    (vim.fn.bufload buf)
    (tset vim.bo buf :filetype :markdown)
    (vim.cmd "botright split")
    (vim.api.nvim_win_set_buf 0 buf)
    (tset vim.wo :wrap true)
    (try_attach_copilot 1)
    buf))

(fn M.open_in_window [filepath ?opts]
  "Open file in floating window (currently unused)"
  (let [cfg (config.get)
        opts (or ?opts {})
        width (or opts.width cfg.window.width)
        height (or opts.height cfg.window.height)
        buf (vim.fn.bufadd filepath)]
    (vim.fn.bufload buf)
    (tset vim.bo buf :filetype :markdown)
    (vim.api.nvim_open_win buf true
      {:relative :editor
       :style cfg.window.style
       :border cfg.window.border
       :row (math.max 0 (- vim.o.lines height 4))
       :col 2
       :height height
       :width width})
    (tset vim.wo :wrap true)
    (try_attach_copilot 1)
    buf))

(fn M.create [?title]
  "Create new memo with optional title"
  (if ?title
    (let [_ (ensure_memos_dir)
          filename (M.generate_filename ?title)
          filepath (M.get_filepath filename)
          initial_tags (get_initial_tags)
          content (M.generate_template ?title initial_tags)]
      (let [(file err) (io.open filepath :w)]
        (if file
          (do
            (file:write content)
            (file:close))
          (vim.notify (.. "Failed to create memo: " (or err "unknown error")) vim.log.levels.ERROR)))
      (M.open_in_split filepath)
      (goto_last_line)
      (state.set_last_edited filename)
      (state.add_recent filename)
      filepath)
    (create_centered_input "Memo title:" M.create)))

(fn M.open [filepath]
  "Open specific memo"
  (let [filename (vim.fn.fnamemodify filepath ":t")]
    (M.open_in_split filepath)
    (state.set_last_edited filename)
    (state.add_recent filename)))

(fn M.open_last []
  "Open the last edited memo"
  (let [last_path (state.get_last_edited)]
    (if (and last_path (= (vim.fn.filereadable last_path) 1))
      (M.open last_path)
      (do
        (vim.notify "No recent memo found. Creating new one..." vim.log.levels.INFO)
        (M.create)))))

(fn M.list []
  "Get list of all memo files sorted by date (newest first)"
  (ensure_memos_dir)
  (let [dir (config.get_memos_dir)
        files (vim.fn.glob (.. dir "/*.md") false true)]
    (table.sort files (fn [a b] (> a b)))
    files))

(fn M.delete [filepath]
  "Delete a memo file"
  (when (= (vim.fn.filereadable filepath) 1)
    (os.remove filepath)
    true))

(fn M.get_memo_info [filepath]
  "Extract memo metadata"
  (let [filename (vim.fn.fnamemodify filepath ":t")
        date_part (filename:match "^(%d+_%d+)_")
        title_part (-> filename
                      (: :match "^%d+_%d+_(.+)%.md$")
                      (or "untitled"))]
    {:filepath filepath
     :filename filename
     :date date_part
     :title (title_part:gsub "-" " ")}))

;; Export for testing
(tset M :_sanitize_title sanitize_title)
(tset M :_get_initial_tags get_initial_tags)

M
