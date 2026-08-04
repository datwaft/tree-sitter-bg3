#include "tree_sitter/parser.h"

#include <stdbool.h>
#include <stdint.h>

enum TokenType {
  NEWLINE,
  END_OF_FILE,
};

void *tree_sitter_bg3_stats_external_scanner_create(void) { return NULL; }

void tree_sitter_bg3_stats_external_scanner_destroy(void *payload) {
  (void)payload;
}

unsigned tree_sitter_bg3_stats_external_scanner_serialize(
    void *payload,
    char *buffer
) {
  (void)payload;
  (void)buffer;
  return 0;
}

void tree_sitter_bg3_stats_external_scanner_deserialize(
    void *payload,
    const char *buffer,
    unsigned length
) {
  (void)payload;
  (void)buffer;
  (void)length;
}

bool tree_sitter_bg3_stats_external_scanner_scan(
    void *payload,
    TSLexer *lexer,
    const bool *valid_symbols
) {
  (void)payload;

  if (valid_symbols[NEWLINE]) {
    if (lexer->lookahead == '\r') {
      lexer->advance(lexer, false);
      if (lexer->lookahead == '\n') {
        lexer->advance(lexer, false);
      }
      lexer->result_symbol = NEWLINE;
      return true;
    }

    if (lexer->lookahead == '\n') {
      lexer->advance(lexer, false);
      lexer->result_symbol = NEWLINE;
      return true;
    }
  }

  if (valid_symbols[END_OF_FILE] && lexer->eof(lexer)) {
    lexer->result_symbol = END_OF_FILE;
    return true;
  }

  return false;
}
