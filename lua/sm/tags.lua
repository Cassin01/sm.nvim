local M = {}
local config = require("sm.config")
local tags_cache = nil
local cache_timestamp = 0
local cache_ttl = 30
local function cache_valid_3f()
  return (tags_cache and ((os.time() - cache_timestamp) < cache_ttl))
end
M["invalidate-cache"] = function()
  tags_cache = nil
  return nil
end
M["parse-frontmatter"] = function(content)
  local frontmatter_pattern = "^%-%-%-\n(.-)\n%-%-%-"
  local frontmatter = content:match(frontmatter_pattern)
  if frontmatter then
    local tags_line = frontmatter:match("tags:%s*%[([^%]]*)%]")
    local created = frontmatter:match("created:%s*([^\n]+)")
    local tags = {}
    if tags_line then
      for tag in tags_line:gmatch("([^,]+)") do
        local trimmed = tag:gsub("^%s+", ""):gsub("%s+$", "")
        if (#trimmed > 0) then
          table.insert(tags, trimmed)
        else
        end
      end
    else
    end
    return {tags = tags, created = created, raw = frontmatter}
  else
    return {tags = {}, created = nil, raw = nil}
  end
end
M["read-file-content"] = function(filepath)
  local file, err = io.open(filepath, "r")
  if file then
    local content = file:read("*all")
    file:close()
    return content
  else
    return nil
  end
end
M["get-memo-tags"] = function(filepath)
  local content = M["read-file-content"](filepath)
  if content then
    return M["parse-frontmatter"](content).tags
  else
    return {}
  end
end
M["build-tags-index"] = function()
  if cache_valid_3f() then
    return tags_cache
  else
    local memo = require("sm.memo")
    local files = memo.list()
    local index = {}
    for _, filepath in ipairs(files) do
      local tags = M["get-memo-tags"](filepath)
      local filename = vim.fn.fnamemodify(filepath, ":t")
      for _0, tag in ipairs(tags) do
        if (index[tag] == nil) then
          index[tag] = {}
        else
        end
        table.insert(index[tag], filename)
      end
    end
    tags_cache = index
    cache_timestamp = os.time()
    return index
  end
end
M["get-memos-by-tag"] = function(tag)
  local index = M["build-tags-index"]()
  local filenames = (index[tag] or {})
  local dir = config["get-memos-dir"]()
  local function _8_(_241)
    return (dir .. "/" .. _241)
  end
  return vim.tbl_map(_8_, filenames)
end
M["list-all-tags"] = function()
  local index = M["build-tags-index"]()
  local tags = {}
  for tag, _ in pairs(index) do
    table.insert(tags, tag)
  end
  table.sort(tags)
  return tags
end
M["get-tags-with-counts"] = function()
  local index = M["build-tags-index"]()
  local result = {}
  for tag, files in pairs(index) do
    table.insert(result, {tag = tag, count = #files})
  end
  local function _9_(a, b)
    return (a.count > b.count)
  end
  table.sort(result, _9_)
  return result
end
M["add-tag-to-memo"] = function(filepath, tag)
  local content = M["read-file-content"](filepath)
  if content then
    local meta = M["parse-frontmatter"](content)
    local tags = meta.tags
    if not vim.tbl_contains(tags, tag) then
      table.insert(tags, tag)
      local new_tags_line = ("tags: [" .. table.concat(tags, ", ") .. "]")
      local new_content = content:gsub("tags:%s*%[[^%]]*%]", new_tags_line, 1)
      local file, err = io.open(filepath, "w")
      if file then
        file:write(new_content)
        file:close()
        M["invalidate-cache"]()
        return true
      else
        vim.notify(("Failed to add tag: " .. (err or "unknown error")), vim.log.levels.ERROR)
        return false
      end
    else
      return nil
    end
  else
    return nil
  end
end
M["remove-tag-from-memo"] = function(filepath, tag)
  local content = M["read-file-content"](filepath)
  if content then
    local meta = M["parse-frontmatter"](content)
    local tags
    local function _13_(_241)
      return (_241 ~= tag)
    end
    tags = vim.tbl_filter(_13_, meta.tags)
    local new_tags_line = ("tags: [" .. table.concat(tags, ", ") .. "]")
    local new_content = content:gsub("tags:%s*%[[^%]]*%]", new_tags_line, 1)
    local file, err = io.open(filepath, "w")
    if file then
      file:write(new_content)
      file:close()
      M["invalidate-cache"]()
      return true
    else
      vim.notify(("Failed to remove tag: " .. (err or "unknown error")), vim.log.levels.ERROR)
      return false
    end
  else
    return nil
  end
end
return M
