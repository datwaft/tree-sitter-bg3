vim.bo.commentstring = "// %s"
vim.bo.comments = "://"
vim.bo.suffixesadd = ".txt"

local bg3 = require("bg3")
if bg3.options.indent then vim.bo.indentexpr = "v:lua.require'bg3'.indentexpr()" end

bg3.start(0)
