;;; sm/api_test.fnl - Tests for api module

;; Setup Lua path for compiled modules
(set package.path (.. "./lua/?.lua;" package.path))

;; Track mock calls for verification
(var last-open-memo-call nil)
(var last-nvim-put-call nil)

;; Mock vim BEFORE requiring modules
(when (not _G.vim)
  (set _G.vim {:fn {:fnamemodify (fn [path modifier]
                                   (if (= modifier ":t:r")
                                       (let [basename (path:match "([^/]+)$")]
                                         (basename:match "(.+)%.md$"))
                                       (= modifier ":t")
                                       (path:match "([^/]+)$")
                                       path))}
               :api {:nvim_put (fn [lines mode after follow]
                                 (set last-nvim-put-call {:lines lines :mode mode}))}}))

;; Mock sm.memo
(tset package.loaded :sm.memo
      {:list (fn []
               ["/tmp/memos/20260117_120000_first-memo.md"
                "/tmp/memos/20260116_100000_second-memo.md"])
       :get-memo-info (fn [filepath]
                        (let [filename (filepath:match "([^/]+)$")
                              date-part (filename:match "^(%d+_%d+)_")
                              title-part (-> filename
                                           (: :match "^%d+_%d+_(.+)%.md$")
                                           (: :gsub "-" " "))]
                          {:filepath filepath
                           :filename filename
                           :date date-part
                           :title title-part}))
       :open (fn [filepath]
               (set last-open-memo-call filepath)
               true)})

;; Mock sm.tags
(tset package.loaded :sm.tags
      {:get-memo-tags (fn [filepath]
                        (if (filepath:match "first")
                            ["work" "ideas"]
                            []))
       :get-tags-with-counts (fn []
                               [{:tag "work" :count 3}
                                {:tag "ideas" :count 2}])
       :get-memos-by-tag (fn [tag]
                           (if (= tag "work")
                               ["/tmp/memos/20260117_120000_first-memo.md"]
                               []))})

;; Mock sm.config
(tset package.loaded :sm.config
      {:get-memos-dir (fn [] "/tmp/test-memos")})

;; Now require the module under test
(local api (require :sm.api))

;; Test get_memos
(let [memos (api.get_memos)]
  (assert (= (length memos) 2) "get_memos: returns 2 entries")
  (let [first-entry (. memos 1)]
    (assert first-entry.value "get_memos: entry has value")
    (assert first-entry.text "get_memos: entry has text")
    (assert first-entry.ordinal "get_memos: entry has ordinal")
    (assert first-entry.info "get_memos: entry has info")
    (assert first-entry.tags "get_memos: entry has tags")
    (assert (first-entry.text:match "%[work, ideas%]") "get_memos: text includes tags")
    (assert (= (length first-entry.tags) 2) "get_memos: first entry has 2 tags"))
  (let [second-entry (. memos 2)]
    (assert (not (second-entry.text:match "%[")) "get_memos: no brackets when no tags")
    (assert (= (length second-entry.tags) 0) "get_memos: second entry has 0 tags")))

;; Test get_tags
(let [tags (api.get_tags)]
  (assert (= (length tags) 2) "get_tags: returns 2 entries")
  (let [first-tag (. tags 1)]
    (assert (= first-tag.value "work") "get_tags: value is tag name")
    (assert (= first-tag.count 3) "get_tags: count is present")
    (assert (first-tag.text:match "work") "get_tags: text includes tag name")
    (assert (first-tag.text:match "%(3 memos%)") "get_tags: text includes count")))

;; Test get_memos_by_tag
(let [memos (api.get_memos_by_tag "work")]
  (assert (= (length memos) 1) "get_memos_by_tag: returns 1 entry for 'work'")
  (let [entry (. memos 1)]
    (assert entry.value "get_memos_by_tag: entry has value")
    (assert entry.text "get_memos_by_tag: entry has text")
    (assert entry.info "get_memos_by_tag: entry has info")))

(let [empty-memos (api.get_memos_by_tag "nonexistent")]
  (assert (= (length empty-memos) 0) "get_memos_by_tag: returns empty for unknown tag"))

;; Test get_memos_for_link
(let [links (api.get_memos_for_link)]
  (assert (= (length links) 2) "get_memos_for_link: returns 2 entries")
  (let [entry (. links 1)]
    (assert (= entry.value "20260117_120000_first-memo") "get_memos_for_link: value is filename without ext")
    (assert entry.text "get_memos_for_link: entry has text")
    (assert entry.filepath "get_memos_for_link: entry has filepath")))

;; Test open_memo
(set last-open-memo-call nil)
(api.open_memo "/tmp/test/memo.md")
(assert (= last-open-memo-call "/tmp/test/memo.md") "open_memo: delegates to memo.open")

;; Test insert_link
(set last-nvim-put-call nil)
(api.insert_link "my-memo")
(assert last-nvim-put-call "insert_link: calls nvim_put")
(assert (= (. last-nvim-put-call.lines 1) "[[my-memo]]") "insert_link: formats as wiki link")

;; Test get_memos_dir
(let [dir (api.get_memos_dir)]
  (assert (= dir "/tmp/test-memos") "get_memos_dir: delegates to config"))

(print "api_test.lua: All tests passed")
