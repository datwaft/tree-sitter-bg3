local M = {}

function M.start(buffer)
  buffer = buffer or 0
  if not vim.treesitter.language.add("bg3_stats") then return false end

  if not vim.treesitter.language.add("bg3_stats_value") then return false end

  vim.treesitter.start(buffer, "bg3_stats")
  return true
end

return M
