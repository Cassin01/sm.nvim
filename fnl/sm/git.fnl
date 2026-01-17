;;; sm/git.fnl - Git repository utilities for sm.nvim

(local M {})

(fn M.is_git_repo []
  "Check if current working directory is inside a git repository.
   Uses finddir to search upward from cwd for .git directory.
   Returns: boolean"
  (let [git_dir (vim.fn.finddir ".git" ".;")]
    (and git_dir (> (length git_dir) 0))))

(fn M.get_repo_name []
  "Extract repository name from git repo root directory.
   Returns: string repo name or nil if not in a git repo"
  (let [git_dir (vim.fn.finddir ".git" ".;")]
    (when (and git_dir (> (length git_dir) 0))
      (vim.fn.fnamemodify git_dir ":h:t"))))

(fn M.sanitize_repo_name [name]
  "Convert repo name to safe tag format (lowercase, hyphens for separators)"
  (when name
    (-> name
        (: :lower)
        (: :gsub "[^%w%-]+" "-")
        (: :gsub "^%-+" "")
        (: :gsub "%-+$" "")
        (: :gsub "%-%-+" "-"))))

(fn M.get_repo_tag []
  "Get sanitized repository name suitable for use as a tag.
   Returns: string tag or nil if not in a git repo"
  (M.sanitize_repo_name (M.get_repo_name)))

M
