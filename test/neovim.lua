local root = vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)))
vim.opt.runtimepath:prepend(root)
vim.opt.runtimepath:prepend(root .. "/build")
vim.opt.swapfile = false
vim.opt.undofile = false
vim.opt.shadafile = "NONE"
vim.cmd("filetype plugin on")

vim.cmd("edit " .. vim.fn.fnameescape(root .. "/examples/Public/Example/Stats/Generated/Data/Passive.txt"))

assert(vim.bo.filetype == "bg3_stats", "expected bg3_stats filetype, got " .. vim.bo.filetype)
assert(vim.bo.commentstring == "// %s", "expected BG3 commentstring")
assert(vim.bo.indentexpr:find("require'bg3'", 1, true), "expected BG3 indent expression")

local parser = vim.treesitter.get_parser(0, "bg3_stats")
local trees = parser:parse(true)
assert(#trees == 1, "expected one outer BG3 syntax tree")
assert(not trees[1]:root():has_error(), "outer BG3 syntax tree contains errors")
assert(vim.treesitter.query.get("bg3_stats", "highlights"), "missing outer highlight query")
assert(vim.treesitter.query.get("bg3_stats_value", "highlights"), "missing value highlight query")

local injected = false
parser:for_each_tree(function(tree, language_tree)
  if language_tree:lang() == "bg3_stats_value" then
    injected = true
    assert(not tree:root():has_error(), "injected BG3 value syntax tree contains errors")
  end
end)
assert(injected, "expected at least one bg3_stats_value injection")

local ordinary = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_name(ordinary, root .. "/examples/notes.txt")
vim.api.nvim_buf_set_lines(ordinary, 0, -1, false, { "ordinary prose" })
local ordinary_filetype = vim.filetype.match({ buf = ordinary })
assert(ordinary_filetype ~= "bg3_stats", "ordinary .txt files must not be detected as BG3 Stats")

local outside_stats = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_name(outside_stats, root .. "/examples/outside-stats.txt")
vim.api.nvim_buf_set_lines(outside_stats, 0, -1, false, {
  'new entry "Outside_Stats_Generated"',
  'type "PassiveData"',
  'data "Boosts" "ActionResource(ActionPoint,1)"',
})
assert(
  vim.filetype.match({ buf = outside_stats }) ~= "bg3_stats",
  "BG3-looking text outside Stats/Generated must not be detected"
)

print("tree-sitter-bg3 Neovim smoke test passed")
vim.cmd("quitall!")
