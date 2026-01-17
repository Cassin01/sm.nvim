;;; sm/state_test.fnl - Tests for state

;; Setup path for standalone execution
(let [fennel (require :fennel)]
  (set fennel.path (.. "./fnl/?.fnl;" fennel.path)))

;; Simple JSON implementation for testing
(fn json-encode [data]
  (if (= (type data) "table")
      (do
        (var is-array true)
        (var i 1)
        (each [k _ (pairs data)]
          (when (not= k i) (set is-array false))
          (set i (+ i 1)))
        (if is-array
            (.. "[" (table.concat (icollect [_ v (ipairs data)] (json-encode v)) ",") "]")
            (.. "{" (table.concat
                      (icollect [k v (pairs data)]
                        (.. "\"" (tostring k) "\":" (json-encode v))) ",") "}")))
      (= (type data) "string") (.. "\"" data "\"")
      (= (type data) "number") (tostring data)
      (= (type data) "boolean") (if data "true" "false")
      "null"))

(fn json-decode [str]
  ;; Replace JSON brackets with markers to avoid conflicts
  (var result (-> str
                  (: :gsub "{" "<<<LBRACE>>>")
                  (: :gsub "}" "<<<RBRACE>>>")
                  (: :gsub "%[" "<<<LBRACK>>>")
                  (: :gsub "%]" "<<<RBRACK>>>")))
  ;; Handle keys: "key": -> ["key"]=
  (set result (string.gsub result "\"([^\"]+)\":"
                (fn [key] (.. "<<<LBRACK>>>\"" key "\"<<<RBRACK>>>="))))
  ;; Handle booleans and null
  (set result (-> result
                  (: :gsub "=true" "=true")
                  (: :gsub "=false" "=false")
                  (: :gsub "=null" "=nil")))
  ;; Restore brackets
  (set result (-> result
                  (: :gsub "<<<LBRACE>>>" "{")
                  (: :gsub "<<<RBRACE>>>" "}")
                  (: :gsub "<<<LBRACK>>>" "[")
                  (: :gsub "<<<RBRACK>>>" "]")))
  (let [func (load (.. "return " result))]
    (func)))

;; Mock dependencies BEFORE requiring modules
(when (not _G.vim)
  (set _G.vim {:tbl_deep_extend (fn [_ t1 t2]
                                  (let [result {}]
                                    (each [k v (pairs t1)] (tset result k v))
                                    (each [k v (pairs t2)] (tset result k v))
                                    result))
               :fn {:isdirectory (fn [path]
                                   ;; Check if directory exists by trying to open it
                                   (let [(handle err) (io.open (.. path "/."))]
                                     (if handle
                                         (do (handle:close) 1)
                                         0)))
                    :mkdir (fn [path mode]
                             ;; Actually create the directory
                             (os.execute (.. "mkdir -p \"" path "\"")))
                    :fnamemodify (fn [path modifier]
                                   (if (= modifier ":h")
                                       (or (path:match "(.+)/[^/]+$") ".")
                                       path))
                    :json_decode json-decode
                    :json_encode json-encode}}))
(tset package.loaded :kaza.file {:nvim-cache (fn [] "/tmp/test-nvim-cache")})

(local M (require :sm.state))

;; Test read-json with non-existent file
(let [result (M._read-json "/tmp/sm_nonexistent_test.json")]
  (assert (= (type result) "table") "read: returns table for missing file")
  (assert (= (next result) nil) "read: returns empty table"))

;; Test write-json / read-json roundtrip
(let [test-file "/tmp/sm_test_state.json"
      data {:test "value" :num 42 :nested {:a 1}}]
  (assert (M._write-json test-file data) "write: returns true on success")
  (let [loaded (M._read-json test-file)]
    (assert (= loaded.test "value") "roundtrip: string value")
    (assert (= loaded.num 42) "roundtrip: number value")
    (assert (= loaded.nested.a 1) "roundtrip: nested value"))
  (os.remove test-file))

;; Test write-json creates directory
(let [test-file "/tmp/sm_test_dir/nested/state.json"
      data {:created true}]
  (M._write-json test-file data)
  (let [loaded (M._read-json test-file)]
    (assert (= loaded.created true) "write: creates nested dirs"))
  (os.remove test-file)
  (os.execute "rm -rf /tmp/sm_test_dir"))

;; Test read-json with empty file
(let [test-file "/tmp/sm_empty_test.json"
      (file) (io.open test-file :w)]
  (file:close)
  (let [result (M._read-json test-file)]
    (assert (= (type result) "table") "read: handles empty file"))
  (os.remove test-file))

(print "state_test.fnl: All tests passed")
