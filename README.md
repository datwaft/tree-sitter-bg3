# tree-sitter-bg3

> [!WARNING]
> This whole repository is 100% vibe-coded.
>
> **Why?** Because I wanted to do some BG3 modding and didn't have time to create a custom grammar from zero.

Tree-sitter grammars for [Baldur's Gate 3](https://baldursgate3.game/) Stats files.

This repository contains two grammars:

- `bg3_stats` parses the outer, line-oriented Stats format.
- `bg3_stats_value` parses expressions injected into quoted `data` values.

The grammars are intended to provide syntax information for editor features such as highlighting, indentation, folding, and injections in Neovim.

## Usage in Neovim

Install this repository as a Neovim plugin so its filetype detection and
filetype settings are available:

```lua
{ "datwaft/tree-sitter-bg3", lazy = false }
```

Then configure one of the following parser managers.

### nvim-treesitter

Register both grammars before installing them:

```lua
vim.api.nvim_create_autocmd("User", {
  pattern = "TSUpdate",
  callback = function()
    local parsers = require("nvim-treesitter.parsers")

    parsers.bg3_stats = {
      install_info = {
        url = "https://github.com/datwaft/tree-sitter-bg3",
        location = "tree-sitter-bg3-stats",
        queries = "tree-sitter-bg3-stats/queries",
      },
    }

    parsers.bg3_stats_value = {
      install_info = {
        url = "https://github.com/datwaft/tree-sitter-bg3",
        location = "tree-sitter-bg3-stats-value",
        queries = "tree-sitter-bg3-stats-value/queries",
      },
    }
  end,
})

require("nvim-treesitter").install({ "bg3_stats", "bg3_stats_value" })
```

See the [nvim-treesitter documentation](https://github.com/nvim-treesitter/nvim-treesitter#adding-custom-languages) for the complete plugin setup.

### Arborist

Add both grammars to `ensure_installed` and point their overrides at this repository:

```lua
{
  "arborist-ts/arborist.nvim",
  lazy = false,
  opts = {
    ensure_installed = {
      "bg3_stats",
      "bg3_stats_value",
    },
    overrides = {
      bg3_stats = {
        url = "https://github.com/datwaft/tree-sitter-bg3",
        location = "tree-sitter-bg3-stats",
      },
      bg3_stats_value = {
        url = "https://github.com/datwaft/tree-sitter-bg3",
        location = "tree-sitter-bg3-stats-value",
      },
    },
  },
}
```

The bundled filetype detection recognizes `.txt` files below a `Stats/Generated` directory. For files elsewhere, use `:setfiletype bg3_stats`.

The plugin also detects `.lsx` files as `bg3_lsx` and uses Neovim's XML parser
for the outer document. Selected `LSString` fields, including `Boosts`,
`Selectors`, and typed symbol lists, inject `bg3_stats_value`. XML entities are
not decoded before injection, so escaped expression text can have partial
highlighting.

## License

[MIT](LICENSE)
