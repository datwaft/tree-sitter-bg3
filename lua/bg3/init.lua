local M = {
  options = {
    auto_start = true,
    indent = true,
  },
}

function M.setup(options) M.options = vim.tbl_deep_extend("force", M.options, options or {}) end

local function shiftwidth()
  local width = vim.bo.shiftwidth
  if width == 0 then width = vim.bo.tabstop end
  return width
end

function M.indentexpr()
  local line_number = vim.v.lnum
  local line = vim.fn.getline(line_number)
  local trimmed = line:match("^%s*(.-)%s*$")

  if trimmed == "" then return -1 end

  if trimmed:match("^//") then
    local previous = vim.fn.prevnonblank(line_number - 1)
    return previous > 0 and vim.fn.indent(previous) or 0
  end

  if trimmed:match("^new%s+") then
    if trimmed:match("^new%s+subtable%s+") then return shiftwidth() end
    return 0
  end

  if trimmed:match("^data%s+") then return shiftwidth() * 2 end

  if
    trimmed:match("^type%s+")
    or trimmed:match("^using%s+")
    or trimmed:match("^add%s+")
    or trimmed:match("^CanMerge%s+")
  then
    return shiftwidth()
  end

  if trimmed:match("^object%s+category%s+") then return shiftwidth() * 2 end

  return 0
end

function M.start(buffer)
  buffer = buffer or 0
  if not M.options.auto_start then return false end

  if not vim.treesitter.language.add("bg3_stats") then return false end

  if not vim.treesitter.language.add("bg3_stats_value") then return false end

  vim.treesitter.start(buffer, "bg3_stats")
  return true
end

return M
