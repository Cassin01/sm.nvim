;;; sm/tags.fnl - Tag parsing and indexing for sm.nvim

(local M {})
(local config (require :sm.config))

;; Tag index cache
(var tags-cache nil)
(var cache-timestamp 0)
(local cache-ttl 30)  ; 30 seconds TTL

(fn cache-valid? []
  "Check if cache is still valid"
  (and tags-cache (< (- (os.time) cache-timestamp) cache-ttl)))

(fn M.invalidate-cache []
  "Force cache invalidation (call after modifying tags)"
  (set tags-cache nil))

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
  "Scan all memos and build tag -> files mapping (cached)
   Returns: {:tag1 [file1 file2] :tag2 [file3] ...}"
  (if (cache-valid?)
    tags-cache
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
      (set tags-cache index)
      (set cache-timestamp (os.time))
      index)))

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
            (if file
              (do
                (file:write new-content)
                (file:close)
                (M.invalidate-cache)
                true)
              (do
                (vim.notify (.. "Failed to add tag: " (or err "unknown error")) vim.log.levels.ERROR)
                false))))))))

(fn M.remove-tag-from-memo [filepath tag]
  "Remove tag from memo's frontmatter"
  (let [content (M.read-file-content filepath)]
    (when content
      (let [meta (M.parse-frontmatter content)
            tags (vim.tbl_filter #(not= $1 tag) meta.tags)
            new-tags-line (.. "tags: [" (table.concat tags ", ") "]")
            new-content (content:gsub "tags:%s*%[[^%]]*%]" new-tags-line 1)
            (file err) (io.open filepath :w)]
        (if file
          (do
            (file:write new-content)
            (file:close)
            (M.invalidate-cache)
            true)
          (do
            (vim.notify (.. "Failed to remove tag: " (or err "unknown error")) vim.log.levels.ERROR)
            false))))))

M
