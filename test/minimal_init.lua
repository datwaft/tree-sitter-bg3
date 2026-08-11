local root = assert(vim.env.BG3_TEST_ROOT, "BG3_TEST_ROOT is required")
local plenary = assert(vim.env.PLENARY_PATH, "PLENARY_PATH is required")

vim.opt.runtimepath:prepend(root)
vim.opt.runtimepath:prepend(root .. "/build")
vim.opt.runtimepath:prepend(plenary)
vim.opt.swapfile = false
vim.opt.undofile = false
vim.opt.shadafile = "NONE"
vim.cmd("filetype plugin on")
vim.cmd.runtime("plugin/bg3_lsf.lua")
