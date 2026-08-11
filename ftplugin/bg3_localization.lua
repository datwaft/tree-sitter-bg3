-- BG3 localization uses the standard XML grammar with readable inline markup.
vim.treesitter.language.register("xml", "bg3_localization")
if vim.treesitter.get_parser(0, "xml", { error = false }) then vim.treesitter.start(0, "xml") end
require("bg3_localization").setup(0)

vim.bo.commentstring = "<!-- %s -->"
vim.wo.conceallevel = 2
vim.wo.concealcursor = "nc"
