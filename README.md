# tree-sitter-bg3

Tree-sitter grammars for [Baldur's Gate 3](https://baldursgate3.game/) data,
Thoth files, and Osiris goals.

This repository contains four grammars:

- `bg3_stats` parses the outer, line-oriented Stats format.
- `bg3_stats_value` parses expressions injected into quoted `data` values.
- `bg3_thoth` parses `.khn` helpers, including Thoth `try` and `catch` statements.
- `bg3_osiris` parses loose Osiris goals below `Story/RawFiles/Goals`.

The grammars are intended to provide syntax information for editor features such as highlighting, indentation, folding, and injections in Neovim.

## Usage in Neovim

Install this repository as a Neovim plugin so its filetype detection and
filetype settings are available:

```lua
{ "datwaft/tree-sitter-bg3", lazy = false }
```

Then configure one of the following parser managers.

### nvim-treesitter

Register all four grammars before installing them:

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

    parsers.bg3_thoth = {
      install_info = {
        url = "https://github.com/datwaft/tree-sitter-bg3",
        location = "tree-sitter-bg3-thoth",
        queries = "tree-sitter-bg3-thoth/queries",
      },
    }

    parsers.bg3_osiris = {
      install_info = {
        url = "https://github.com/datwaft/tree-sitter-bg3",
        location = "tree-sitter-bg3-osiris",
        queries = "tree-sitter-bg3-osiris/queries",
      },
    }
  end,
})

require("nvim-treesitter").install({ "bg3_stats", "bg3_stats_value", "bg3_thoth", "bg3_osiris" })
```

See the [nvim-treesitter documentation](https://github.com/nvim-treesitter/nvim-treesitter#adding-custom-languages) for the complete plugin setup.

### Arborist

Add all four grammars to `ensure_installed` and point their overrides at this
repository:

```lua
{
  "arborist-ts/arborist.nvim",
  lazy = false,
  opts = {
    ensure_installed = {
      "bg3_stats",
      "bg3_stats_value",
      "bg3_thoth",
      "bg3_osiris",
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
      bg3_thoth = {
        url = "https://github.com/datwaft/tree-sitter-bg3",
        location = "tree-sitter-bg3-thoth",
      },
      bg3_osiris = {
        url = "https://github.com/datwaft/tree-sitter-bg3",
        location = "tree-sitter-bg3-osiris",
      },
    },
  },
}
```

The bundled filetype detection recognizes `.txt` files below a
`Stats/Generated` directory as `bg3_stats`. It recognizes `.txt` files below
`Story/RawFiles/Goals` as `bg3_osiris`. Other text files remain unclaimed.

The plugin also detects `.lsx` files as `bg3_lsx` and uses Neovim's XML parser
for the outer document. Selected `LSString` fields, including `Boosts`,
`Selectors`, and typed symbol lists, inject `bg3_stats_value`. XML entities are
not decoded before injection, so escaped expression text can have partial
highlighting.

The plugin detects `.khn` files as `bg3_thoth`. The Thoth grammar derives from
[`tree-sitter-lua`](https://github.com/tree-sitter-grammars/tree-sitter-lua)
commit `10fe005`. The repository vendors the grammar source and adds the
verified `try` and `catch` syntax used by BG3 helper scripts. The upstream
grammar remains under its original MIT license in
[`LICENSE.tree-sitter-lua`](LICENSE.tree-sitter-lua).

The Osiris grammar parses raw goal metadata, INIT, KB, and EXIT sections,
`IF`, `PROC`, and `QRY` rules, typed values, comparisons, facts, actions, and
parent-goal edges. It provides syntax structure only. It does not compile or
execute a Story, validate engine APIs, or infer Osiris types.

## License

[MIT](LICENSE)
