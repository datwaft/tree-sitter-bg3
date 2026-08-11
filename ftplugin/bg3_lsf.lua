-- Transparent LSF buffers contain the textual LSX representation.
vim.treesitter.language.register("xml", "bg3_lsf")

vim.bo.commentstring = "<!-- %s -->"
