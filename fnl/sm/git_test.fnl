;;; sm/git_test.fnl - Tests for git utilities

;; Setup Lua path for compiled modules
(set package.path (.. "./lua/?.lua;" package.path))

;; Mock state for testing
(var mock-finddir-result "")

;; Mock vim API BEFORE requiring modules
(when (not _G.vim)
  (fn deepcopy [t]
    (if (= (type t) :table)
      (let [copy {}]
        (each [k v (pairs t)]
          (tset copy k (deepcopy v)))
        copy)
      t))
  (set _G.vim {:tbl_deep_extend (fn [_ t1 t2]
                                  (let [result {}]
                                    (each [k v (pairs t1)] (tset result k v))
                                    (each [k v (pairs t2)] (tset result k v))
                                    result))
               :deepcopy deepcopy
               :fn {:stdpath (fn [which] "/tmp/test-nvim-cache")
                    :finddir (fn [name path] mock-finddir-result)
                    :fnamemodify (fn [path modifier]
                                   (if (= modifier ":h")
                                       (or (path:match "^(.+)/[^/]+$") ".")
                                       (= modifier ":t")
                                       (or (path:match "([^/]+)$") path)
                                       (= modifier ":h:t")
                                       (let [parent (or (path:match "^(.+)/[^/]+$") ".")]
                                         (or (parent:match "([^/]+)$") parent))
                                       path))}}))

;; Helper to set mock state
(fn set_git_mock [finddir-result]
  (set mock-finddir-result finddir-result))

(local M (require :sm.git))

;; Test 1: is_git_repo returns false when not in git repo
(set_git_mock "")
(assert (= (M.is_git_repo) false) "is_git_repo: false when no .git found")

;; Test 2: is_git_repo returns true when in git repo
(set_git_mock "/path/to/project/.git")
(assert (= (M.is_git_repo) true) "is_git_repo: true when .git found")

;; Test 3: get_repo_name returns nil when not in git repo
(set_git_mock "")
(assert (= (M.get_repo_name) nil) "get_repo_name: nil when not in repo")

;; Test 4: get_repo_name extracts directory name
(set_git_mock "/home/user/projects/awesome-project/.git")
(assert (= (M.get_repo_name) "awesome-project") "get_repo_name: extracts dir name")

;; Test 5: sanitize_repo_name handles various formats
(assert (= (M.sanitize_repo_name "My Project") "my-project") "sanitize: spaces to hyphens")
(assert (= (M.sanitize_repo_name "Project_Name") "project-name") "sanitize: underscores to hyphens")
(assert (= (M.sanitize_repo_name "UPPERCASE") "uppercase") "sanitize: lowercase")
(assert (= (M.sanitize_repo_name "--prefix--") "prefix") "sanitize: trim leading/trailing hyphens")
(assert (= (M.sanitize_repo_name nil) nil) "sanitize: handles nil input")
(assert (= (M.sanitize_repo_name "sm.nvim") "sm-nvim") "sanitize: dots to hyphens")
(assert (= (M.sanitize_repo_name "---") nil) "sanitize: returns nil for only-special-chars")
(assert (= (M.sanitize_repo_name "...") nil) "sanitize: returns nil for only dots")
(assert (= (M.sanitize_repo_name "") nil) "sanitize: returns nil for empty string")

;; Test 6: get_repo_tag combines detection and sanitization
(set_git_mock "/path/to/SM.nvim/.git")
(assert (= (M.get_repo_tag) "sm-nvim") "get_repo_tag: sanitized repo name")

(set_git_mock "")
(assert (= (M.get_repo_tag) nil) "get_repo_tag: nil when not in repo")

(print "git_test.lua: All tests passed")
