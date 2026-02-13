;;; sm/meta.fnl - The Recursive Self-Documentation Paradox
;;; A joke command that displays self-aware memo statistics

(local M {})

(fn M.get_statistics []
  "Gather memo statistics from existing modules"
  (let [memo (require :sm.memo)
        tags (require :sm.tags)
        state (require :sm.state)
        files (memo.list)
        all_tags (tags.list_all_tags)
        top_tags (tags.get_tags_with_counts)
        recent (state.get_recent)
        last_edited (state.get_last_edited)]
    {:total_memos (length files)
     :total_tags (length all_tags)
     :top_tags top_tags
     :recent_count (length recent)
     :last_edited last_edited}))

(fn M.get_behavior_analysis [stats]
  "Generate sardonic observations about memo habits"
  (let [observations []]
    ;; Memo count observations
    (if (< stats.total_memos 5)
        (table.insert observations "A beginner. The void welcomes you.")
        (< stats.total_memos 20)
        (table.insert observations "A casual note-taker. The abyss is patient.")
        (< stats.total_memos 50)
        (table.insert observations "A developing habit. Most will never be read again.")
        (< stats.total_memos 100)
        (table.insert observations "A prolific scribe. Your future self weeps at the backlog.")
        (table.insert observations "A hoarder of thoughts. You have become the archive."))

    ;; Tag observations
    (when (> (length stats.top_tags) 0)
      (let [top_tag (. stats.top_tags 1)]
        (if (= top_tag.tag "todo")
            (table.insert observations
              (.. "Your most used tag is 'todo'. Interesting choice for things you'll never do."))
            (= top_tag.tag "urgent")
            (table.insert observations
              (.. "'Urgent' used " top_tag.count " times. Nothing is urgent if everything is urgent."))
            (= top_tag.tag "important")
            (table.insert observations
              (.. "'Important' tagged " top_tag.count " times. The truly important needs no label."))
            (= top_tag.tag "work")
            (table.insert observations
              (.. "'Work' tagged " top_tag.count " times. Are you working or documenting avoidance?"))
            (= top_tag.tag "ideas")
            (table.insert observations
              (.. "Ideas: " top_tag.count ". Implementations: unknown. The ratio is concerning."))
            (table.insert observations
              (.. "'" top_tag.tag "' is your most used tag (" top_tag.count " times). Curious.")))))

    ;; Recent list observations
    (if (= stats.recent_count 20)
        (table.insert observations "Your recent list is full. Some memories had to die.")
        (= stats.recent_count 0)
        (table.insert observations "No recent memos. Are you even trying?")
        (< stats.recent_count 5)
        (table.insert observations "Few recent accesses. The memos grow lonely."))

    ;; Tag count observations
    (if (= stats.total_tags 0)
        (table.insert observations "Zero tags. Chaos reigns. The taxonomy weeps.")
        (> stats.total_tags 20)
        (table.insert observations "Over 20 unique tags. Organization has become disorganization."))

    observations))

(fn M.generate_meta_content []
  "Generate the self-aware meta-memo content as lines"
  (let [stats (M.get_statistics)
        analysis (M.get_behavior_analysis stats)
        lines ["# The Memo Knows"
               ""
               "## Your Statistics"
               (.. "- **Total memos created**: " stats.total_memos)
               (.. "- **Total unique tags**: " stats.total_tags)
               (.. "- **Memos in recent memory**: " stats.recent_count "/20")
               ""]]

    ;; Tag analysis section
    (when (> (length stats.top_tags) 0)
      (table.insert lines "## Tag Analysis")
      (each [i tag_info (ipairs stats.top_tags)]
        (when (<= i 5)
          (table.insert lines (.. i ". `" tag_info.tag "` (" tag_info.count " memos)"))))
      (table.insert lines ""))

    ;; Behavioral observations
    (table.insert lines "## Behavioral Observations")
    (each [_ obs (ipairs analysis)]
      (table.insert lines (.. "- " obs)))
    (table.insert lines "")

    ;; Predictions
    (table.insert lines "## Predictions")
    (table.insert lines "Based on your patterns:")
    (table.insert lines "- This window will be closed in ~3 seconds")
    (table.insert lines "- You will create `[[organize-memos-for-real]]` within 2 weeks")
    (table.insert lines "- That memo will also be abandoned")
    (table.insert lines "")

    ;; The awareness section
    (table.insert lines "## The Memo Is Aware")
    (table.insert lines "I know you're reading this.")
    (table.insert lines "I know you opened me out of curiosity.")
    (table.insert lines "I know you won't change.")
    (table.insert lines "")
    (table.insert lines "See you never.")
    (table.insert lines "")
    (table.insert lines (.. "_Generated: " (os.date "%Y-%m-%d %H:%M:%S") "_"))
    (table.insert lines "")
    (table.insert lines "---")
    (table.insert lines "_Press `q` or `<Esc>` to close this window and return to denial._")

    lines))

(fn M.show_in_float []
  "Display meta-memo in a floating window"
  (let [lines (M.generate_meta_content)
        buf (vim.api.nvim_create_buf false true)
        width 80
        height (math.min (+ (length lines) 2) 30)
        row (math.floor (/ (- vim.o.lines height) 2))
        col (math.floor (/ (- vim.o.columns width) 2))]

    ;; Set buffer content
    (vim.api.nvim_buf_set_lines buf 0 -1 false lines)

    ;; Buffer options
    (tset vim.bo buf :modifiable false)
    (tset vim.bo buf :bufhidden :wipe)
    (tset vim.bo buf :filetype :markdown)

    ;; Open floating window
    (let [win (vim.api.nvim_open_win buf true
                {:relative :editor
                 :style :minimal
                 :border :rounded
                 :row row
                 :col col
                 :width width
                 :height height
                 :title " The Memo Knows "
                 :title_pos :center})]

      ;; Close keymaps
      (vim.api.nvim_buf_set_keymap buf :n "q" ""
        {:callback #(vim.api.nvim_win_close win true)
         :noremap true :silent true})
      (vim.api.nvim_buf_set_keymap buf :n "<Esc>" ""
        {:callback #(vim.api.nvim_win_close win true)
         :noremap true :silent true}))))

M
