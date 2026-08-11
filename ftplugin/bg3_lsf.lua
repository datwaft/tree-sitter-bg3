-- Transparent LSF buffers contain the textual LSX representation.
vim.treesitter.language.register("xml", "bg3_lsf")
vim.treesitter.start(0, "xml")

vim.bo.commentstring = "<!-- %s -->"
