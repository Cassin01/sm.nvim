local M = {}
M.get_repo_name = function()
  local git_dir = vim.fn.finddir(".git", ".;")
  if (git_dir and (#git_dir > 0)) then
    return vim.fn.fnamemodify(git_dir, ":h:t")
  else
    return nil
  end
end
M.is_git_repo = function()
  return (M.get_repo_name() ~= nil)
end
M.sanitize_repo_name = function(name)
  if name then
    local sanitized = name:lower():gsub("[^%w%-]+", "-"):gsub("^%-+", ""):gsub("%-+$", ""):gsub("%-%-+", "-")
    if (#sanitized > 0) then
      return sanitized
    else
      return nil
    end
  else
    return nil
  end
end
M.get_repo_tag = function()
  return M.sanitize_repo_name(M.get_repo_name())
end
return M
