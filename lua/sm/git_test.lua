package.path = ("./lua/?.lua;" .. package.path)
local mock_finddir_result = ""
if not _G.vim then
  local function deepcopy(t)
    if (type(t) == "table") then
      local copy = {}
      for k, v in pairs(t) do
        copy[k] = deepcopy(v)
      end
      return copy
    else
      return t
    end
  end
  local function _2_(_, t1, t2)
    local result = {}
    for k, v in pairs(t1) do
      result[k] = v
    end
    for k, v in pairs(t2) do
      result[k] = v
    end
    return result
  end
  local function _3_(which)
    return "/tmp/test-nvim-cache"
  end
  local function _4_(name, path)
    return mock_finddir_result
  end
  local function _5_(path, modifier)
    if (modifier == ":h") then
      return (path:match("^(.+)/[^/]+$") or ".")
    elseif (modifier == ":t") then
      return (path:match("([^/]+)$") or path)
    elseif (modifier == ":h:t") then
      local parent = (path:match("^(.+)/[^/]+$") or ".")
      return (parent:match("([^/]+)$") or parent)
    else
      return path
    end
  end
  _G.vim = {tbl_deep_extend = _2_, deepcopy = deepcopy, fn = {stdpath = _3_, finddir = _4_, fnamemodify = _5_}}
else
end
local function set_git_mock(finddir_result)
  mock_finddir_result = finddir_result
  return nil
end
local M = require("sm.git")
set_git_mock("")
assert((M.is_git_repo() == false), "is_git_repo: false when no .git found")
set_git_mock("/path/to/project/.git")
assert((M.is_git_repo() == true), "is_git_repo: true when .git found")
set_git_mock("")
assert((M.get_repo_name() == nil), "get_repo_name: nil when not in repo")
set_git_mock("/home/user/projects/awesome-project/.git")
assert((M.get_repo_name() == "awesome-project"), "get_repo_name: extracts dir name")
assert((M.sanitize_repo_name("My Project") == "my-project"), "sanitize: spaces to hyphens")
assert((M.sanitize_repo_name("Project_Name") == "project-name"), "sanitize: underscores to hyphens")
assert((M.sanitize_repo_name("UPPERCASE") == "uppercase"), "sanitize: lowercase")
assert((M.sanitize_repo_name("--prefix--") == "prefix"), "sanitize: trim leading/trailing hyphens")
assert((M.sanitize_repo_name(nil) == nil), "sanitize: handles nil input")
assert((M.sanitize_repo_name("sm.nvim") == "sm-nvim"), "sanitize: dots to hyphens")
set_git_mock("/path/to/SM.nvim/.git")
assert((M.get_repo_tag() == "sm-nvim"), "get_repo_tag: sanitized repo name")
set_git_mock("")
assert((M.get_repo_tag() == nil), "get_repo_tag: nil when not in repo")
return print("git_test.lua: All tests passed")
