;;; sm/tags.fnl - Tag parsing and indexing for sm.nvim

(local M {})
(local config (require :sm.config))

(fn M.parse-frontmatter [content]
  "Parse YAML frontmatter and extract metadata
   Returns: {:tags [...] :created ... :raw ...}"
  (let [frontmatter-pattern "^%-%-%-\n(.-)\n%-%-%-"
        frontmatter (content:match frontmatter-pattern)]
    (if frontmatter
      (let [tags-line (frontmatter:match "tags:%s*%[([^%]]*)%]")
            created (frontmatter:match "created:%s*([^\n]+)")
            tags []]
        (when tags-line
          (each [tag (tags-line:gmatch "([^,]+)")]
            (let [trimmed (-> tag
                             (: :gsub "^%s+" "")
                             (: :gsub "%s+$" ""))]
              (when (> (length trimmed) 0)
                (table.insert tags trimmed)))))
        {:tags tags
         :created created
         :raw frontmatter})
      {:tags []
       :created nil
       :raw nil})))

(fn M.read-file-content [filepath]
  "Read file content"
  (let [(file err) (io.open filepath :r)]
    (if file
      (let [content (file:read :*all)]
        (file:close)
        content)
      nil)))

(fn M.get-memo-tags [filepath]
  "Read file and extract tags from frontmatter"
  (let [content (M.read-file-content filepath)]
    (if content
      (. (M.parse-frontmatter content) :tags)
      [])))

(fn M.build-tags-index []
  "Scan all memos and build tag -> files mapping
   Returns: {:tag1 [file1 file2] :tag2 [file3] ...}"
  (let [memo (require :sm.memo)
        files (memo.list)
        index {}]
    (each [_ filepath (ipairs files)]
      (let [tags (M.get-memo-tags filepath)
            filename (vim.fn.fnamemodify filepath ":t")]
        (each [_ tag (ipairs tags)]
          (when (= (. index tag) nil)
            (tset index tag []))
          (table.insert (. index tag) filename))))
    index))

(fn M.get-memos-by-tag [tag]
  "Return list of memo filepaths with given tag"
  (let [index (M.build-tags-index)
        filenames (or (. index tag) [])
        dir (config.get-memos-dir)]
    (vim.tbl_map #(.. dir "/" $1) filenames)))

(fn M.list-all-tags []
  "Return sorted list of all unique tags"
  (let [index (M.build-tags-index)
        tags []]
    (each [tag _ (pairs index)]
      (table.insert tags tag))
    (table.sort tags)
    tags))

(fn M.get-tags-with-counts []
  "Return list of {tag count} pairs sorted by count"
  (let [index (M.build-tags-index)
        result []]
    (each [tag files (pairs index)]
      (table.insert result {:tag tag :count (length files)}))
    (table.sort result (fn [a b] (> a.count b.count)))
    result))

(fn M.add-tag-to-memo [filepath tag]
  "Add tag to memo's frontmatter"
  (let [content (M.read-file-content filepath)]
    (when content
      (let [meta (M.parse-frontmatter content)
            tags meta.tags]
        (when (not (vim.tbl_contains tags tag))
          (table.insert tags tag)
          (let [new-tags-line (.. "tags: [" (table.concat tags ", ") "]")
                new-content (content:gsub "tags:%s*%[[^%]]*%]" new-tags-line 1)
                (file err) (io.open filepath :w)]
            (when file
              (file:write new-content)
              (file:close)
              true)))))))

(fn M.remove-tag-from-memo [filepath tag]
  "Remove tag from memo's frontmatter"
  (let [content (M.read-file-content filepath)]
    (when content
      (let [meta (M.parse-frontmatter content)
            tags (vim.tbl_filter #(not= $1 tag) meta.tags)
            new-tags-line (.. "tags: [" (table.concat tags ", ") "]")
            new-content (content:gsub "tags:%s*%[[^%]]*%]" new-tags-line 1)
            (file err) (io.open filepath :w)]
        (when file
          (file:write new-content)
          (file:close)
          true)))))

;;; test (run with: fennel fnl/sm/tags.fnl)

(local (method-name) ...)
(when (= method-name nil)
  ;; Test parse-frontmatter with tags
  (let [content "---\ntags: [work, ideas]\ncreated: 2026-01-17\n---\n# Test"
        result (M.parse-frontmatter content)]
    (assert (= (length result.tags) 2) "parse: tag count")
    (assert (= (. result.tags 1) "work") "parse: first tag")
    (assert (= (. result.tags 2) "ideas") "parse: second tag")
    (assert (= result.created "2026-01-17") "parse: created date"))

  ;; Test parse-frontmatter with empty tags
  (let [content "---\ntags: []\ncreated: 2026-01-17\n---\n# Test"
        result (M.parse-frontmatter content)]
    (assert (= (length result.tags) 0) "parse: empty tags"))

  ;; Test parse-frontmatter without frontmatter
  (let [result (M.parse-frontmatter "No frontmatter here")]
    (assert (= (length result.tags) 0) "parse: no frontmatter")
    (assert (= result.created nil) "parse: no created"))

  ;; Test parse-frontmatter with spaces in tags
  (let [content "---\ntags: [ tag1 , tag2 , tag3 ]\n---\n"
        result (M.parse-frontmatter content)]
    (assert (= (length result.tags) 3) "parse: tags with spaces")
    (assert (= (. result.tags 1) "tag1") "parse: trimmed tag"))

  (print "tags.fnl: All tests passed"))

M
