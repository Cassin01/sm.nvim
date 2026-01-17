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
      (: :gsub "[^%w%-%_]+" "-")
      (: :gsub "^%-+" "")
      (: :gsub "%-+$" "")
      (: :gsub "%-%-+" "-")))

(fn M.generate_filename [title]
  "Generate filename: YYYYMMDD_HHMMSS_{sanitized-title}.md"
  (let [cfg (config.get)
        date (os.date cfg.date_format)
        safe_title (sanitize_title title)]
    (.. date "_" safe_title ".md")))

(fn M.generate_template [title]
  "Generate memo content from template"
  (let [cfg (config.get)
        date_str (os.date "%Y-%m-%dT%H:%M:%S")
        lines []]
    (each [_ line (ipairs cfg.template)]
      (local processed (-> line
                          (: :gsub "%%date%%" date_str)
                          (: :gsub "%%title%%" title)))
      (table.insert lines processed))
    (table.concat lines "\n")))

(fn M.get_filepath [filename]
  "Get full path for a memo filename"
  (.. (config.get_memos_dir) "/" filename))

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

(fn M.open_in_window [filepath ?opts]
  "Open file in floating window"
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
       :row 3
       :col (- vim.o.columns width 2)
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
          content (M.generate_template ?title)]
      (let [(file err) (io.open filepath :w)]
        (if file
          (do
            (file:write content)
            (file:close))
          (vim.notify (.. "Failed to create memo: " (or err "unknown error")) vim.log.levels.ERROR)))
      (M.open_in_window filepath)
      (state.set_last_edited filename)
      (state.add_recent filename)
      filepath)
    (vim.ui.input {:prompt "Memo title: "}
      (fn [input]
        (when (and input (> (length input) 0))
          (M.create input))))))

(fn M.open [filepath]
  "Open specific memo"
  (let [filename (vim.fn.fnamemodify filepath ":t")]
    (M.open_in_window filepath)
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

M
