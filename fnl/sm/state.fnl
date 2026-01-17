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

;;; test (run with: fennel fnl/sm/state.fnl)

(local (method-name) ...)
(when (= method-name nil)
  ;; Test read-json with non-existent file
  (let [result (read-json "/tmp/sm_nonexistent_test.json")]
    (assert (= (type result) "table") "read: returns table for missing file")
    (assert (= (next result) nil) "read: returns empty table"))

  ;; Test write-json / read-json roundtrip
  (let [test-file "/tmp/sm_test_state.json"
        data {:test "value" :num 42 :nested {:a 1}}]
    (assert (write-json test-file data) "write: returns true on success")
    (let [loaded (read-json test-file)]
      (assert (= loaded.test "value") "roundtrip: string value")
      (assert (= loaded.num 42) "roundtrip: number value")
      (assert (= loaded.nested.a 1) "roundtrip: nested value"))
    (os.remove test-file))

  ;; Test write-json creates directory
  (let [test-file "/tmp/sm_test_dir/nested/state.json"
        data {:created true}]
    (write-json test-file data)
    (let [loaded (read-json test-file)]
      (assert (= loaded.created true) "write: creates nested dirs"))
    (os.remove test-file)
    (os.execute "rm -rf /tmp/sm_test_dir"))

  ;; Test read-json with empty file
  (let [test-file "/tmp/sm_empty_test.json"
        (file) (io.open test-file :w)]
    (file:close)
    (let [result (read-json test-file)]
      (assert (= (type result) "table") "read: handles empty file"))
    (os.remove test-file))

  (print "state.fnl: All tests passed"))

M
