-- LSX uses the standard XML grammar. The separate filetype lets language
-- servers attach to BG3 resources without attaching to all XML files.
vim.treesitter.language.register("xml", "bg3_lsx")

vim.bo.commentstring = "<!-- %s -->"
