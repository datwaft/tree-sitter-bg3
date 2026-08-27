# Repository Instructions

These instructions apply to all work in `tree-sitter-bg3`. Keep the grammars
accurate, portable, and conservative about syntax that has not been verified.
Prefer a small, evidenced grammar or query change to a broad speculative one.

## Product Direction

`tree-sitter-bg3` provides syntax grammars, editor queries, Rust bindings, and
lightweight Neovim runtime support for loose Baldur's Gate 3 mod data. It is a
syntax project. It does not compile Story, execute game scripts, validate game
APIs, or replace `bg3-ls` semantic analysis.

Maintain these component boundaries:

- `tree-sitter-bg3-stats` owns the outer, line-oriented legacy Stats grammar.
- `tree-sitter-bg3-stats-value` owns expressions injected into Stats and
  selected LSX string fields.
- `tree-sitter-bg3-thoth` owns Thoth syntax. It remains based on the documented
  `tree-sitter-lua` revision plus verified BG3-specific syntax.
- `tree-sitter-bg3-osiris` owns loose Osiris goal syntax.
- Each grammar directory owns the queries that depend on its syntax tree.
- `ftdetect`, `ftplugin`, `lua`, `plugin`, and top-level `queries` own Neovim
  file detection and editor integration that spans grammars or external XML.
- `bindings/rust` exposes all four generated parsers without adding semantic
  behavior.

Keep `tree-sitter.json`, Cargo metadata, npm metadata, and the README aligned
with the grammars that the repository actually provides. Do not make users
install a separate Neovim plugin to use the bundled runtime files.

Use this repository as the syntax contract for `bg3-ls`. Put semantic rules,
workspace discovery, schemas, diagnostics, and language-server coordination in
`bg3-ls`. Change a grammar only when valid syntax, useful error recovery, or an
editor query needs a different syntax tree.

## Grammar and Query Correctness

Base grammar changes on verified syntax from the game, public tooling behavior,
or a minimal synthetic reproduction derived from such evidence. Do not broaden
a grammar only because a plausible construct might exist.

Preserve the distinction between these defect classes:

- A grammar defect means the syntax tree cannot represent verified valid text,
  represents it with the wrong structure, or recovers in a harmful way.
- A query defect means the syntax tree is correct but highlighting, injection,
  indentation, folding, locals, or tags produce incorrect editor behavior.
- A Neovim runtime defect means file detection, buffer options, localization
  display, or transparent LSF editing is incorrect outside the grammar.
- A `bg3-ls` defect belongs in the language-server repository.
- A mod defect does not require a repository change.

Parsing success alone does not prove editor correctness. Test the observable
query behavior when a change affects highlighting, injection, indentation,
folding, locals, or tags.

Keep line- and column-sensitive source contracts explicit even when whitespace
is a grammar extra. In particular, Osiris structural directives that BG3
requires at column zero must stay at column zero after Neovim reindentation.

Prefer a syntax error or a narrow recovery node to silently accepting an
unknown format. Preserve useful incomplete-edit recovery, but do not let error
recovery redefine the accepted language.

## Generated and Vendored Sources

Treat each `grammar.js` as the primary grammar source. The corresponding
`src/grammar.json`, `src/node-types.json`, and `src/parser.c` files are generated
artifacts and must agree with it.

Generate parser artifacts when a grammar changes. Inspect the complete
generated diff. Do not hand-edit generated parser files, and do not include
generator-version churn for unaffected grammars.

Scanner sources are not all generated. Read the applicable scanner before
editing it, preserve its allocation and serialization contracts, and add corpus
coverage for scanner changes.

The Thoth grammar and license derive from `tree-sitter-lua`. Preserve
`LICENSE.tree-sitter-lua`, document any upstream baseline change, and do not
replace vendored code without reviewing both behavior and license effects.

## Source and Test Data

Use synthetic fixtures in the repository. Never commit installed BG3 data,
unpacked mods, `.pak` contents, user paths, or copyrighted localization text.

Installed data can support a local smoke test. Do not include that data in a
patch, corpus file, test snapshot, benchmark output, issue, or pull request.
Reduce every regression to the smallest useful synthetic fixture before commit.

Keep fixtures structurally representative without copying game content. Use
obviously synthetic identifiers, UUIDs, localization text, paths, and values.

## Implementation Process

Before a change:

1. Read the applicable grammar, scanner, queries, runtime files, and tests.
2. Reproduce a reported defect when reproduction is possible.
3. Classify it as a grammar, query, Neovim runtime, `bg3-ls`, or mod defect.
4. Confirm the public behavior and acceptance criteria.
5. Check the current Jujutsu status before edits.

Use concrete, top-down JavaScript, Lua, C, and Rust. Add a helper or named
concept only when it isolates fragile behavior, reduces meaningful nesting,
expresses stable domain structure, or can be tested independently. Fail clearly
on unknown input. Do not use a silent fallback.

Keep comments focused on syntax constraints and non-obvious compatibility
decisions. Do not narrate the code. Preserve the existing grammar DSL and query
style unless the task explicitly requires a broader cleanup.

After a change:

1. Add or update corpus and integration tests for observable behavior.
2. Regenerate parsers when a grammar changed.
3. Run the applicable verification commands.
4. Inspect the complete diff, including generated artifacts.
5. Update the README and manifests when public behavior or packaging changes.
6. Make an explicit release-version decision.

## Required Verification

Run the complete repository suite for grammar, query, or Neovim runtime
changes:

```sh
make test
```

Use the narrower targets during development when useful:

```sh
make test-grammar
make test-neovim
```

`make test` runs generation before the tests. After it finishes, inspect
`jj status` and exclude generated changes from unaffected grammars.

For Rust binding or package changes, run:

```sh
cargo fmt --all --check
cargo test
cargo clippy --all-targets -- -D warnings
```

Run `stylua --check` on affected Lua files. For a release, also validate both
package layouts without publishing them:

```sh
cargo package --allow-dirty
npm pack --dry-run
```

Use a real editor or installed mod only as a local smoke test. A smoke test does
not replace a synthetic corpus or integration regression test. When claiming a
parser performance improvement, benchmark representative synthetic or private
local data before and after the change and report the method without exposing
installed data.

## Issue Policy

Create a GitHub issue before substantial work when one of these conditions is
true:

- A user reports a reproducible grammar, query, or Neovim runtime defect.
- The repository needs a new grammar, query capability, filetype integration,
  binding, or supported source format.
- A change needs a syntax design decision or more than one pull request.
- A discovered valid problem is outside the active issue.
- A parser performance regression needs measurement and follow-up work.

Do not create a separate issue for a small correction necessary to complete the
active issue. Do not create a `tree-sitter-bg3` issue for a confirmed mod or
language-server defect.

A useful bug issue contains:

- the affected version or commit;
- the expected and actual parse tree or editor behavior;
- a minimal synthetic example or safe reproduction procedure;
- the grammar, query capture, filetype, or runtime component involved;
- the probable defect class, when known;
- clear acceptance criteria.

Use concise technical English. Preserve uncertainty when the syntax contract is
not fully known. Do not include private paths or installed game data.

## Jujutsu Commit Process

Use Jujutsu for all version-control writes. Jujutsu and Git share this
repository so that `gh` can create issues and pull requests. Use Git directly
only when Jujutsu cannot perform a required Git operation, such as creating an
annotated release tag.

Start new work from current `main`:

```sh
jj git fetch
jj new main
jj status
```

Make one coherent commit for one logical change. Include its generated files,
tests, and required documentation in the same commit. Do not mix cleanup or
unrelated grammar changes with a feature or fix.

Use an active Conventional Commit title:

```text
feat: parse Osiris goal declarations
fix: keep section terminators at column zero
docs: define the grammar contribution process
test: cover incomplete Stats expressions
perf: reduce external scanner allocations
refactor: isolate Thoth exception syntax
chore: prepare v0.5.0
```

Keep the title concise. Use a body when the evidence, syntax compatibility
limit, generated change, or safety constraint is not clear from the diff.
Report only verification that actually ran.

Describe the current commit without an interactive editor:

```sh
jj describe -m "fix: describe the change"
```

Inspect `jj status`, `jj diff`, and `jj log` before publication. Do not use Git
commands to mutate commits, bookmarks, or the worktree.

## Pull Request Process

Create a pull request for every change that enters `main`. Do not push a change
directly to `main`. Keep each issue in one focused pull request unless a clear
review sequence requires more than one commit.

A small documentation, CI, or maintenance pull request does not need an issue.
Omit `Closes #123` when no issue exists. Explain why the repository needs the
change in the pull request body.

Use a `codex/` bookmark with the issue number and a short topic when an issue
exists. Use a similarly concise topic when no issue exists:

```sh
jj bookmark create codex/issue-123-short-topic -r @
jj git push --bookmark codex/issue-123-short-topic
```

Use the commit title as the pull request title when possible. Use this pull
request body structure:

```markdown
Closes #123

## Problem

State the user-visible syntax or editor problem and its effect.

## Change

- State the important grammar, query, runtime, or packaging changes.
- State intentional syntax limits and recovery behavior.

## Verification

- List the corpus, integration, binding, and package checks that ran.
- List a local smoke test only when it supplied useful evidence.
```

Use ASD-STE100 Issue 9 structural rules as guidance for issue, commit, and pull
request text. Controlled-dictionary verification is not required. Keep grammar
node names, query captures, commands, identifiers, paths, and filetypes exact.

Wait for required checks. Do not merge a pull request with failed checks,
unresolved conflicts, or known acceptance failures. When the task grants merge
authority, use a squash merge and delete the remote bookmark. Otherwise, leave
the pull request ready for review.

When the user explicitly authorizes immediate merging after local verification,
the pull request may be merged without waiting for hosted CI when the applicable
local checks pass. For this repository, run `npm ci`, `make test`,
`cargo fmt --all --check`, `cargo test --workspace --locked`,
`cargo clippy --workspace --all-targets --locked -- -D warnings`,
`cargo package --allow-dirty --locked`, and `npm pack --dry-run`, then inspect
the complete diff. For workflow changes, also run
`./test/release-workflow.sh` and `actionlint`. Hosted CI remains required for
workflow changes,
dependency or lockfile changes, release or version changes, security or
permissions changes, generated parser artifacts, and platform-sensitive
Neovim or runtime changes. The release workflow and this policy change are
workflow changes, so this pull request must wait for hosted CI.

After a merge:

```sh
jj git fetch
jj new main
jj status
```

Confirm that `main` contains the squash merge and that the working copy has no
changes. Run post-merge verification when several dependent pull requests form
one release batch.

## Version and Release Process

Every user-visible batch must finish with an explicit release decision. Do not
merge grammar or editor behavior and silently leave stale package metadata.

While the project is below `1.0.0`, use these version rules:

- Increase the patch version for compatible grammar fixes, query fixes, runtime
  fixes, and documentation corrections that do not add a new public capability.
- Increase the minor version for a new grammar, accepted syntax family, query
  capability, binding, filetype integration, or other compatible feature.
- Increase the minor version and document migration steps for an incompatible
  syntax-tree, query, binding, or runtime change. Do not make an incompatible
  change without an approved design issue.
- Internal test or agent-instruction changes do not require a release unless
  they also alter the shipped package or user documentation.

Use a dedicated release pull request after a user-visible batch. Use
`chore: prepare vX.Y.Z` as its title. The release pull request must:

1. Update `Cargo.toml` and `Cargo.lock`.
2. Update `package.json` and `package-lock.json`.
3. Update `tree-sitter.json` metadata when it contains a package version.
4. Update versioned README text and installation examples.
5. Summarize user-visible changes and migration requirements.
6. Run the complete grammar, Neovim, Rust, and package verification suite.
7. Confirm the documented `tree-sitter-lua` baseline when Thoth changed.

After the release pull request merges, create an annotated `vX.Y.Z` tag from
the squash merge on `main`. Push the tag and create GitHub release notes. Never
tag a pull request commit. Do not reuse or move a published version tag.

All manifests, lockfiles, release tags, and package dry-runs must report the
same version. Do not publish to crates.io or npm unless the active task grants
that authority and the package registries are configured.

## Documentation and Compatibility

Update the README and `tree-sitter.json` for every public grammar, binding, or
installation change. Keep standard Tree-sitter consumers and Neovim supported;
do not make editor queries depend on private local configuration.

Preserve the documented transparent LSF integration with `bg3-ls`, but keep LSF
conversion logic in the language server. Keep XML-based LSX and localization
integration usable when optional parsers or tools are unavailable, as documented.

Document intentional omissions. Do not imply that these grammars compile Story,
validate game APIs, parse packed files, decode every XML entity before injection,
or support unverified syntax.

## Scope Control

Do not add semantic validation, code generation, compilation, packed-file
extraction, project discovery, or language-server features as incidental work.
Open a design issue when one of these capabilities becomes necessary.

Do not rewrite a grammar wholesale to fix one construct. Do not update the
vendored Thoth baseline, generated parser toolchain, or public node structure as
incidental cleanup.

Do not push unrelated bookmarks or rewrite published history. Do not publish
packages, tags, or releases unless the active task includes that authority.
