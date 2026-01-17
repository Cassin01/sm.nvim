;;; sm/tags.fnl - Tag parsing and indexing for sm.nvim

(local M {})
(local config (require :sm.config))

;; Tag index cache (using single table for atomic updates)
(var cache {:data nil :timestamp 0})
(local cache_ttl 30)  ; 30 seconds TTL

(fn cache_valid? []
  "Check if cache is still valid (atomic read)"
  (let [c cache]  ; atomic read of entire cache state
    (and c.data (< (- (os.time) c.timestamp) cache_ttl))))

(fn M.invalidate_cache []
  "Force cache invalidation (call after modifying tags)"
  (set cache {:data nil :timestamp 0}))

(fn M.parse_frontmatter [content]
  "Parse YAML frontmatter and extract metadata
   Returns: {:tags [...] :created ... :raw ...}"
  (let [frontmatter_pattern "^%-%-%-\n(.-)\n%-%-%-"
        frontmatter (content:match frontmatter_pattern)]
    (if frontmatter
      (let [tags_line (frontmatter:match "tags:%s*%[([^%]]*)%]")
            created (frontmatter:match "created:%s*([^\n]+)")
            tags []]
        (when tags_line
          (each [tag (tags_line:gmatch "([^,]+)")]
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

(fn M.read_file_content [filepath]
  "Read file content"
  (let [(file err) (io.open filepath :r)]
    (if file
      (let [content (file:read :*all)]
        (file:close)
        content)
      nil)))

(fn M.get_memo_tags [filepath]
  "Read file and extract tags from frontmatter"
  (let [content (M.read_file_content filepath)]
    (if content
      (. (M.parse_frontmatter content) :tags)
      [])))

(fn M.build_tags_index []
  "Scan all memos and build tag -> files mapping (cached)
   Returns: {:tag1 [file1 file2] :tag2 [file3] ...}"
  (if (cache_valid?)
    cache.data
    (let [memo (require :sm.memo)
          files (memo.list)
          index {}]
      (each [_ filepath (ipairs files)]
        (let [tags (M.get_memo_tags filepath)
              filename (vim.fn.fnamemodify filepath ":t")]
          (each [_ tag (ipairs tags)]
            (when (= (. index tag) nil)
              (tset index tag []))
            (table.insert (. index tag) filename))))
      ;; consistent update: readers see either old or new state, never partial
      (set cache {:data index :timestamp (os.time)})
      index)))

(fn M.get_memos_by_tag [tag]
  "Return list of memo filepaths with given tag"
  (let [index (M.build_tags_index)
        filenames (or (. index tag) [])
        dir (config.get_memos_dir)]
    (vim.tbl_map #(.. dir "/" $1) filenames)))

(fn M.list_all_tags []
  "Return sorted list of all unique tags"
  (let [index (M.build_tags_index)
        tags []]
    (each [tag _ (pairs index)]
      (table.insert tags tag))
    (table.sort tags)
    tags))

(fn M.get_tags_with_counts []
  "Return list of {tag count} pairs sorted by count"
  (let [index (M.build_tags_index)
        result []]
    (each [tag files (pairs index)]
      (table.insert result {:tag tag :count (length files)}))
    (table.sort result (fn [a b] (> a.count b.count)))
    result))

(fn M.add_tag_to_memo [filepath tag]
  "Add tag to memo's frontmatter"
  (let [content (M.read_file_content filepath)]
    (when content
      (let [meta (M.parse_frontmatter content)
            tags meta.tags]
        (when (not (vim.tbl_contains tags tag))
          (table.insert tags tag)
          (let [new_tags_line (.. "tags: [" (table.concat tags ", ") "]")
                new_content (content:gsub "tags:%s*%[[^%]]*%]" new_tags_line 1)
                (file err) (io.open filepath :w)]
            (if file
              (do
                (file:write new_content)
                (file:close)
                (M.invalidate_cache)
                true)
              (do
                (vim.notify (.. "Failed to add tag: " (or err "unknown error")) vim.log.levels.ERROR)
                false))))))))

(fn M.remove_tag_from_memo [filepath tag]
  "Remove tag from memo's frontmatter"
  (let [content (M.read_file_content filepath)]
    (when content
      (let [meta (M.parse_frontmatter content)
            tags (vim.tbl_filter #(not= $1 tag) meta.tags)
            new_tags_line (.. "tags: [" (table.concat tags ", ") "]")
            new_content (content:gsub "tags:%s*%[[^%]]*%]" new_tags_line 1)
            (file err) (io.open filepath :w)]
        (if file
          (do
            (file:write new_content)
            (file:close)
            (M.invalidate_cache)
            true)
          (do
            (vim.notify (.. "Failed to remove tag: " (or err "unknown error")) vim.log.levels.ERROR)
            false))))))

M
