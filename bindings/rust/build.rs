use std::path::Path;

/// Compiles one generated Tree-sitter parser and its optional external scanner.
fn compile_parser(name: &str, source_dir: &Path, scanner: bool) {
    let mut build = cc::Build::new();
    build
        .include(source_dir)
        .file(source_dir.join("parser.c"))
        .warnings(false)
        .std("c11");

    if scanner {
        build.file(source_dir.join("scanner.c"));
    }

    build.compile(name);
}

/// Builds all grammars that the BG3 language server embeds.
fn main() {
    let stats = Path::new("tree-sitter-bg3-stats/src");
    let value = Path::new("tree-sitter-bg3-stats-value/src");
    let thoth = Path::new("tree-sitter-bg3-thoth/src");
    let osiris = Path::new("tree-sitter-bg3-osiris/src");

    compile_parser("tree-sitter-bg3-stats", stats, true);
    compile_parser("tree-sitter-bg3-stats-value", value, false);
    compile_parser("tree-sitter-bg3-thoth", thoth, true);
    compile_parser("tree-sitter-bg3-osiris", osiris, false);

    for source in [
        stats.join("parser.c"),
        stats.join("scanner.c"),
        value.join("parser.c"),
        thoth.join("parser.c"),
        thoth.join("scanner.c"),
        osiris.join("parser.c"),
    ] {
        println!("cargo:rerun-if-changed={}", source.display());
    }
}
