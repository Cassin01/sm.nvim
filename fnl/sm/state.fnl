;;; sm/state.fnl - State persistence for sm.nvim

(local M {})
(local config (require :sm.config))

(fn ensure-dir [path]
  "Create directory if it doesn't exist"
  (when (= (vim.fn.isdirectory path) 0)
    (vim.fn.mkdir path :p)))

(fn read-json [filepath]
  "Read and parse JSON file, return nil if not exists"
  (let [(file err) (io.open filepath :r)]
    (if file
      (let [content (file:read :*all)]
        (file:close)
        (if (and content (> (length content) 0))
          (vim.fn.json_decode content)
          {}))
      {})))

(fn write-json [filepath data]
  "Write data as JSON to file"
  (ensure-dir (vim.fn.fnamemodify filepath ":h"))
  (let [(file err) (io.open filepath :w)]
    (when file
      (file:write (vim.fn.json_encode data))
      (file:close)
      true)))

(fn M.load []
  "Load state from file"
  (read-json (config.get-state-file)))

(fn M.save [state]
  "Save state to file"
  (write-json (config.get-state-file) state))

(fn M.get-last-edited []
  "Get path to last edited memo"
  (let [state (M.load)]
    (when state.last_edited
      (.. (config.get-memos-dir) "/" state.last_edited))))

(fn M.set-last-edited [filename]
  "Update last edited memo in state"
  (let [state (M.load)]
    (tset state :last_edited filename)
    (tset state :last_accessed (os.time))
    (M.save state)))

(fn M.get-recent [?limit]
  "Get list of recently accessed memos"
  (let [state (M.load)
        limit (or ?limit 10)]
    (or state.recent [])))

(fn M.add-recent [filename]
  "Add memo to recent list"
  (let [state (M.load)
        recent (or state.recent [])
        filtered (vim.tbl_filter #(not= $1 filename) recent)]
    (table.insert filtered 1 filename)
    (while (> (length filtered) 20)
      (table.remove filtered))
    (tset state :recent filtered)
    (M.save state)))

;; Export for testing
(tset M :_read-json read-json)
(tset M :_write-json write-json)

M
