//! Rust bindings for the Baldur's Gate 3 data, Thoth, and Osiris grammars.

use tree_sitter_language::LanguageFn;

/// The grammar package version included in cache compatibility fingerprints.
pub const GRAMMAR_VERSION: &str = env!("CARGO_PKG_VERSION");

unsafe extern "C" {
    fn tree_sitter_bg3_stats() -> *const ();
    fn tree_sitter_bg3_stats_value() -> *const ();
    fn tree_sitter_bg3_thoth() -> *const ();
    fn tree_sitter_bg3_osiris() -> *const ();
}

/// The Tree-sitter language for legacy BG3 Stats source files.
pub const BG3_STATS_LANGUAGE: LanguageFn = unsafe { LanguageFn::from_raw(tree_sitter_bg3_stats) };

/// The Tree-sitter language for expressions stored inside Stats values.
pub const BG3_STATS_VALUE_LANGUAGE: LanguageFn =
    unsafe { LanguageFn::from_raw(tree_sitter_bg3_stats_value) };

/// The Tree-sitter language for BG3 Thoth helper source files.
pub const BG3_THOTH_LANGUAGE: LanguageFn = unsafe { LanguageFn::from_raw(tree_sitter_bg3_thoth) };

/// The Tree-sitter language for BG3 Osiris goal source files.
pub const BG3_OSIRIS_LANGUAGE: LanguageFn = unsafe { LanguageFn::from_raw(tree_sitter_bg3_osiris) };

/// Highlight query for legacy BG3 Stats source files.
pub const BG3_STATS_HIGHLIGHTS_QUERY: &str =
    include_str!("../../tree-sitter-bg3-stats/queries/highlights.scm");

/// Injection query that embeds the Stats-value grammar in quoted fields.
pub const BG3_STATS_INJECTIONS_QUERY: &str =
    include_str!("../../tree-sitter-bg3-stats/queries/injections.scm");

/// Highlight query for embedded BG3 Stats values.
pub const BG3_STATS_VALUE_HIGHLIGHTS_QUERY: &str =
    include_str!("../../tree-sitter-bg3-stats-value/queries/highlights.scm");

/// Highlight query for BG3 Thoth helper source files.
pub const BG3_THOTH_HIGHLIGHTS_QUERY: &str =
    include_str!("../../tree-sitter-bg3-thoth/queries/highlights.scm");

/// Highlight query for BG3 Osiris goal source files.
pub const BG3_OSIRIS_HIGHLIGHTS_QUERY: &str =
    include_str!("../../tree-sitter-bg3-osiris/queries/highlights.scm");

#[cfg(test)]
mod tests {
    use super::{
        BG3_OSIRIS_LANGUAGE, BG3_STATS_LANGUAGE, BG3_STATS_VALUE_LANGUAGE, BG3_THOTH_LANGUAGE,
    };
    use tree_sitter::Parser;

    /// Verifies that the generated Stats parser links and accepts representative syntax.
    #[test]
    fn parses_stats_source() {
        let mut parser = Parser::new();
        parser
            .set_language(&BG3_STATS_LANGUAGE.into())
            .expect("the Stats grammar must load");

        let tree = parser
            .parse(
                "new entry \"TEST\"\ntype \"PassiveData\"\ndata \"Boosts\" \"UnlockSpell(Target_Test)\"\n",
                None,
            )
            .expect("the Stats parser must return a tree");

        assert!(!tree.root_node().has_error());
    }

    /// Verifies that the generated value parser links and accepts nested expressions.
    #[test]
    fn parses_stats_value() {
        let mut parser = Parser::new();
        parser
            .set_language(&BG3_STATS_VALUE_LANGUAGE.into())
            .expect("the Stats-value grammar must load");

        let tree = parser
            .parse(
                "IF(HasStatus(TEST_STATUS)):ApplyStatus(TEST_STATUS,100,2)",
                None,
            )
            .expect("the Stats-value parser must return a tree");

        assert!(!tree.root_node().has_error());
    }

    /// Verifies that the Thoth parser accepts Lua-compatible and exception syntax.
    #[test]
    fn parses_thoth_source() {
        let mut parser = Parser::new();
        parser
            .set_language(&BG3_THOTH_LANGUAGE.into())
            .expect("the Thoth grammar must load");

        let tree = parser
            .parse(
                "function SpellDC(entity)\n  try\n    return CalculateSpellDC(entity)\n  catch error then\n    return 10\n  end\nend\n",
                None,
            )
            .expect("the Thoth parser must return a tree");

        assert!(!tree.root_node().has_error());
        assert_eq!(
            tree.root_node().named_child(0).unwrap().kind(),
            "function_declaration"
        );
    }

    /// Verifies that the Osiris parser accepts a representative synthetic goal.
    #[test]
    fn parses_osiris_source() {
        let mut parser = Parser::new();
        parser
            .set_language(&BG3_OSIRIS_LANGUAGE.into())
            .expect("the Osiris grammar must load");

        let tree = parser
            .parse(
                "Version 1\nSubGoalCombiner SGC_AND\nINITSECTION\nKBSECTION\nIF\nExampleEvent((CHARACTER)_Actor)\nTHEN\nDB_Example_Seen(_Actor);\nEXITSECTION\nENDEXITSECTION\n",
                None,
            )
            .expect("the Osiris parser must return a tree");

        assert!(!tree.root_node().has_error());
        assert_eq!(tree.root_node().kind(), "source_file");
    }
}
