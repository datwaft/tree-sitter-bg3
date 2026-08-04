# tree-sitter-bg3

Tree-sitter grammars and lightweight Neovim support for Baldur's Gate 3 Stats
`.txt` files.

The repository follows the split-parser layout used by
[`tree-sitter-markdown`](https://github.com/tree-sitter-grammars/tree-sitter-markdown):

- `bg3_stats` parses the outer line-oriented Stats format.
- `bg3_stats_value` parses expressions injected into quoted `data` values.

Keeping the value language separate gives calls, conditions, resources,
handles, UUIDs, dice, lists, and operators their own syntax tree without making
the outer grammar understand every possible value expression.

## Layout

```text
tree-sitter.json
tree-sitter-bg3-stats/
  grammar.js
  queries/
  src/
  test/corpus/
tree-sitter-bg3-stats-value/
  grammar.js
  queries/
  src/
  test/corpus/
ftdetect/
ftplugin/
lua/
plugin/
```

`tree-sitter.json` is the single repository manifest for both grammars. Query
files live with the grammar that owns them. The Neovim runtime files provide
conservative `.txt` detection, comments, automatic parser start, and
`:BG3InspectTree`. Indentation comes from the outer grammar's `indents.scm`
query and the editor's Tree-sitter indent evaluator.

## Neovim with Arborist

For local development:

```lua
local bg3_path = vim.fn.expand("~/Developer/VimPlugins/tree-sitter-bg3")
local bg3_source = "file://" .. bg3_path

return {
  {
    "arborist-ts/arborist.nvim",
    opts = {
      ensure_installed = { "bg3_stats_value", "bg3_stats" },
      overrides = {
        bg3_stats = {
          url = bg3_source,
          location = "tree-sitter-bg3-stats",
          revision = "main",
        },
        bg3_stats_value = {
          url = bg3_source,
          location = "tree-sitter-bg3-stats-value",
          revision = "main",
        },
      },
    },
  },
  {
    dir = bg3_path,
    name = "tree-sitter-bg3",
    lazy = false,
  },
}
```

The explicit `main` revision is only needed for a local colocated Jujutsu
repository. Once this repository is published, replace the `file://` source
with its GitHub URL, remove `revision`, and replace the local `dir` plugin spec
with `"OWNER/tree-sitter-bg3"`.

The grammars are ordinary Tree-sitter packages and are not coupled to
Arborist. The root manifest and grammar directories can also be consumed by
`nvim-treesitter`, Helix, Zed, or other Tree-sitter integrations.

## File detection

The Neovim runtime detects `.txt` files below a `Stats/Generated` directory.
It does not inspect file contents or claim `.txt` files elsewhere.

For an unusual path:

```vim
:setfiletype bg3_stats
```

## Development

```sh
make generate
make test
```

`make test` runs both corpus suites and a headless Neovim test covering file
detection, highlighting queries, outer parsing, and value-language injection.

Authored grammar files are `grammar.js`, query files, corpus fixtures, and the
outer grammar's `scanner.c`. Tree-sitter CLI output under each `src/` directory
is committed for consumers and marked `linguist-generated` in `.gitattributes`.
Build products stay under the ignored `build/` directory.

## License

MIT
