# tree-sitter-bg3

Tree-sitter grammars for [Baldur's Gate 3](https://baldursgate3.game/) data,
Thoth files, and Osiris goals.

Version 0.4.0 adds transparent loose LSF editing through `bg3-ls`, readable
localization markup, and independent highlighting for `LSTag` tooltip fields.
Version 0.4.1 keeps localization buffers usable when the optional XML parser
is not installed.
Version 0.4.2 keeps the Osiris `ENDEXITSECTION` directive at column zero when
Neovim reindents a goal.
Version 0.4.3 reindents Thoth helpers in the StyLua style: closing tokens
align with their opener, and multi-line call arguments, parenthesized
expressions, and broken operator chains indent one level.
Version 0.5.0 accepts the Unicode ellipsis character in `bg3_stats_value` as a
placeholder for elided content in sequence and argument positions. The
placeholder highlights as a comment, and other expression positions still
reject it.

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

Loose `Localization/<Language>/*.xml` files use the `bg3_localization`
filetype and the standard XML parser. The bundled highlight query displays
`&lt;` and `&gt;` delimiters inside `<content>` values as `<` and `>` while
leaving the source text unchanged. A literal `>` remains visible as written.
Encoded and literal `LSTag` markup highlights tag names, delimiters, Tooltip
attributes, and quoted tooltip keys independently from surrounding prose.
The filetype uses `conceallevel=2` and `concealcursor=nc`, so insert mode shows
the exact entity spelling while normal mode shows readable inline tags. Override
these window options from a `FileType` autocmd if a different editing view is
preferred.

### Transparent LSF editing

With `bg3-ls` 0.8.0 or newer on `PATH`, opening a loose `.lsf` file displays
its textual LSX representation in a `bg3_lsf` buffer. Writing the buffer
compiles it back to LSF. The original binary is replaced only after conversion
succeeds and the result has an `LSOF` signature. File permissions are
preserved, and a save is rejected if another process changed the LSF after it
was opened.

The adapter invokes the converter directly without a shell. Override the
command when testing a source build:

```lua
vim.g.bg3_lsf_converter = { "cargo", "run", "-p", "bg3-ls", "--" }
```

Conversion errors leave the original LSF unchanged and keep the buffer
modified. Use `:edit!` to reload after an external change.

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
