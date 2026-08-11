-- BG3 localization uses the standard XML grammar with readable inline markup.
vim.treesitter.language.register("xml", "bg3_localization")

vim.bo.commentstring = "<!-- %s -->"
vim.wo.conceallevel = 2
vim.wo.concealcursor = "nc"
