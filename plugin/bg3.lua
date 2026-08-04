if vim.g.loaded_bg3_nvim == 1 then return end
vim.g.loaded_bg3_nvim = 1

local bg3 = require("bg3")
bg3.setup()

vim.api.nvim_create_user_command("BG3InspectTree", function() vim.treesitter.inspect_tree({ lang = "bg3_stats" }) end, {
  desc = "Open the BG3 Stats syntax tree inspector",
})
