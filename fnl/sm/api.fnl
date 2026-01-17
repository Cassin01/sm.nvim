;;; sm/api.fnl - Public API for picker integration

(local M {})

(fn M.get_memos []
  "Get all memos as picker entries.
   Returns: Array of {value=filepath, text=display, ordinal=search, info={...}, tags=[...]}"
  (let [memo (require :sm.memo)
        tags-mod (require :sm.tags)
        files (memo.list)
        entries []]
    (each [_ filepath (ipairs files)]
      (let [info (memo.get-memo-info filepath)
            tags (tags-mod.get-memo-tags filepath)
            tags-str (if (> (length tags) 0)
                       (.. " [" (table.concat tags ", ") "]")
                       "")
            display (.. info.date " | " info.title tags-str)
            ordinal (.. info.date " " info.title " " (table.concat tags " "))]
        (table.insert entries
          {:value filepath
           :text display
           :ordinal ordinal
           :info info
           :tags tags})))
    entries))

(fn M.get_tags []
  "Get all tags with counts as picker entries.
   Returns: Array of {value=tag, text=display, ordinal=tag, count=n}"
  (let [tags-mod (require :sm.tags)
        tags-with-counts (tags-mod.get-tags-with-counts)
        entries []]
    (each [_ item (ipairs tags-with-counts)]
      (table.insert entries
        {:value item.tag
         :text (string.format "%-20s (%d memos)" item.tag item.count)
         :ordinal item.tag
         :count item.count}))
    entries))

(fn M.get_memos_by_tag [tag]
  "Get memos filtered by tag as picker entries.
   Returns: Array of {value=filepath, text=display, ordinal=search, info={...}}"
  (let [memo (require :sm.memo)
        tags-mod (require :sm.tags)
        files (tags-mod.get-memos-by-tag tag)
        entries []]
    (each [_ filepath (ipairs files)]
      (let [info (memo.get-memo-info filepath)
            display (.. info.date " | " info.title)
            ordinal (.. info.date " " info.title)]
        (table.insert entries
          {:value filepath
           :text display
           :ordinal ordinal
           :info info})))
    entries))

(fn M.get_memos_for_link []
  "Get memos formatted for link insertion.
   Returns: Array of {value=filename_without_ext, text=display, ordinal=search, filepath=full_path}"
  (let [memo (require :sm.memo)
        files (memo.list)
        entries []]
    (each [_ filepath (ipairs files)]
      (let [info (memo.get-memo-info filepath)
            filename (vim.fn.fnamemodify filepath ":t:r")
            display (.. info.date " | " info.title)
            ordinal (.. info.date " " info.title)]
        (table.insert entries
          {:value filename
           :text display
           :ordinal ordinal
           :filepath filepath})))
    entries))

(fn M.open_memo [filepath]
  "Open a memo file. Use as selection callback."
  (let [memo (require :sm.memo)]
    (memo.open filepath)))

(fn M.insert_link [filename]
  "Insert wiki link at cursor. Use as selection callback.
   filename: The filename without extension to link to"
  (let [link (.. "[[" filename "]]")]
    (vim.api.nvim_put [link] :c true true)))

(fn M.get_memos_dir []
  "Get the memos directory path. Useful for grep operations."
  (let [config (require :sm.config)]
    (config.get-memos-dir)))

M
