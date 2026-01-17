local M = {}
M.is_git_repo = function()
  local git_dir = vim.fn.finddir(".git", ".;")
  return (git_dir and (#git_dir > 0))
end
M.get_repo_name = function()
  local git_dir = vim.fn.finddir(".git", ".;")
  if (git_dir and (#git_dir > 0)) then
    return vim.fn.fnamemodify(git_dir, ":h:t")
  else
    return nil
  end
end
M.sanitize_repo_name = function(name)
  if name then
    return name:lower():gsub("[^%w%-]+", "-"):gsub("^%-+", ""):gsub("%-+$", ""):gsub("%-%-+", "-")
  else
    return nil
  end
end
M.get_repo_tag = function()
  return M.sanitize_repo_name(M.get_repo_name())
end
return M
