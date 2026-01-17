;;; sm/memo.fnl - Core memo operations for sm.nvim

(local M {})
(local config (require :sm.config))
(local state (require :sm.state))

(fn ensure-memos-dir []
  "Create memos directory if it doesn't exist"
  (let [dir (config.get-memos-dir)]
    (when (= (vim.fn.isdirectory dir) 0)
      (vim.fn.mkdir dir :p))
    dir))

(fn sanitize-title [title]
  "Convert title to safe filename component"
  (-> title
      (: :lower)
      (: :gsub "[^%w%-%_]+" "-")
      (: :gsub "^%-+" "")
      (: :gsub "%-+$" "")
      (: :gsub "%-%-+" "-")))

(fn M.generate-filename [title]
  "Generate filename: YYYYMMDD_HHMMSS_{sanitized-title}.md"
  (let [cfg (config.get)
        date (os.date cfg.date-format)
        safe-title (sanitize-title title)]
    (.. date "_" safe-title ".md")))

(fn M.generate-template [title]
  "Generate memo content from template"
  (let [cfg (config.get)
        date-str (os.date "%Y-%m-%dT%H:%M:%S")
        lines []]
    (each [_ line (ipairs cfg.template)]
      (local processed (-> line
                          (: :gsub "%%date%%" date-str)
                          (: :gsub "%%title%%" title)))
      (table.insert lines processed))
    (table.concat lines "\n")))

(fn M.get-filepath [filename]
  "Get full path for a memo filename"
  (.. (config.get-memos-dir) "/" filename))

(fn M.open-in-window [filepath ?opts]
  "Open file in floating window"
  (let [cfg (config.get)
        opts (or ?opts {})
        width (or opts.width cfg.window.width)
        height (or opts.height cfg.window.height)
        buf (vim.fn.bufadd filepath)]
    (vim.fn.bufload buf)
    (vim.api.nvim_buf_set_option buf :filetype :markdown)
    (vim.api.nvim_open_win buf true
      {:relative :editor
       :style cfg.window.style
       :border cfg.window.border
       :row 3
       :col (- vim.o.columns width 2)
       :height height
       :width width})
    (tset vim.wo :wrap true)
    (vim.defer_fn
      (fn []
        (pcall #((. (require :copilot.command) :attach) {:force true})))
      150)
    buf))

(fn M.create [?title]
  "Create new memo with optional title"
  (if ?title
    (let [_ (ensure-memos-dir)
          filename (M.generate-filename ?title)
          filepath (M.get-filepath filename)
          content (M.generate-template ?title)]
      (let [(file err) (io.open filepath :w)]
        (when file
          (file:write content)
          (file:close)))
      (M.open-in-window filepath)
      (state.set-last-edited filename)
      (state.add-recent filename)
      filepath)
    (vim.ui.input {:prompt "Memo title: "}
      (fn [input]
        (when (and input (> (length input) 0))
          (M.create input))))))

(fn M.open [filepath]
  "Open specific memo"
  (let [filename (vim.fn.fnamemodify filepath ":t")]
    (M.open-in-window filepath)
    (state.set-last-edited filename)
    (state.add-recent filename)))

(fn M.open-last []
  "Open the last edited memo"
  (let [last-path (state.get-last-edited)]
    (if (and last-path (= (vim.fn.filereadable last-path) 1))
      (M.open last-path)
      (do
        (vim.notify "No recent memo found. Creating new one..." vim.log.levels.INFO)
        (M.create)))))

(fn M.list []
  "Get list of all memo files sorted by date (newest first)"
  (ensure-memos-dir)
  (let [dir (config.get-memos-dir)
        files (vim.fn.glob (.. dir "/*.md") false true)]
    (table.sort files (fn [a b] (> a b)))
    files))

(fn M.delete [filepath]
  "Delete a memo file"
  (when (= (vim.fn.filereadable filepath) 1)
    (os.remove filepath)
    true))

(fn M.get-memo-info [filepath]
  "Extract memo metadata"
  (let [filename (vim.fn.fnamemodify filepath ":t")
        date-part (filename:match "^(%d+_%d+)_")
        title-part (-> filename
                      (: :match "^%d+_%d+_(.+)%.md$")
                      (or "untitled"))]
    {:filepath filepath
     :filename filename
     :date date-part
     :title (title-part:gsub "-" " ")}))

;;; test (run with: fennel fnl/sm/memo.fnl)

(local (method-name) ...)
(when (= method-name nil)
  ;; Test sanitize-title
  (assert (= (sanitize-title "Hello World!") "hello-world") "sanitize: spaces and punctuation")
  (assert (= (sanitize-title "  Test  ") "test") "sanitize: trim whitespace")
  (assert (= (sanitize-title "My--Title") "my-title") "sanitize: collapse dashes")
  (assert (= (sanitize-title "CamelCase") "camelcase") "sanitize: lowercase")

  ;; Test generate-filename format
  (let [filename (M.generate-filename "test")]
    (assert (filename:match "^%d+_%d+_test%.md$") "filename: format YYYYMMDD_HHMMSS_title.md"))

  ;; Test generate-template
  (let [content (M.generate-template "Test Title")]
    (assert (content:match "^%-%-%-") "template: starts with frontmatter")
    (assert (content:match "tags: %[%]") "template: has empty tags")
    (assert (content:match "# Test Title") "template: has title heading"))

  ;; Test get-memo-info
  (let [info (M.get-memo-info "/path/to/20260117_143052_my-memo.md")]
    (assert (= info.filename "20260117_143052_my-memo.md") "info: filename")
    (assert (= info.date "20260117_143052") "info: date")
    (assert (= info.title "my memo") "info: title with spaces"))

  (print "memo.fnl: All tests passed"))

M
