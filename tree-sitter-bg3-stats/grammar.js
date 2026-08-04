const commaSep1 = (rule) => seq(rule, repeat(seq(',', rule)));

module.exports = grammar({
  name: 'bg3_stats',

  extras: () => [/[\t \f]/],

  externals: ($) => [
    $._newline,
    $._eof,
  ],

  conflicts: ($) => [
    [$.stat_entry],
    [$.treasure_table],
    [$.treasure_subtable],
    [$.equipment_entry],
    [$.named_block],
  ],

  word: ($) => $.identifier,

  rules: {
    source_file: ($) => repeat(choice(
      $.stat_entry,
      $.treasure_table,
      $.equipment_entry,
      $.named_block,
      $.comment,
      $._blank_line,
      $.generic_statement,
    )),

    stat_entry: ($) => seq(
      $.entry_header,
      repeat(choice(
        $.type_clause,
        $.using_clause,
        $.data_clause,
        $.comment,
        $._blank_line,
      )),
    ),

    entry_header: ($) => seq(
      'new',
      'entry',
      field('name', $.quoted_string),
      $._line_end,
    ),

    type_clause: ($) => seq(
      'type',
      field('value', $.quoted_string),
      $._line_end,
    ),

    using_clause: ($) => seq(
      'using',
      field('value', $.quoted_string),
      $._line_end,
    ),

    data_clause: ($) => seq(
      'data',
      field('name', $.quoted_string),
      field('value', $.quoted_string),
      $._line_end,
    ),

    treasure_table: ($) => seq(
      $.treasure_table_header,
      repeat(choice(
        $.merge_clause,
        $.treasure_subtable,
        $.comment,
        $._blank_line,
      )),
    ),

    treasure_table_header: ($) => seq(
      'new',
      'treasuretable',
      field('name', $.quoted_string),
      $._line_end,
    ),

    merge_clause: ($) => seq(
      field('name', alias('CanMerge', $.identifier)),
      field('value', $.number),
      $._line_end,
    ),

    treasure_subtable: ($) => seq(
      $.subtable_header,
      repeat(choice(
        $.object_clause,
        $.comment,
        $._blank_line,
      )),
    ),

    subtable_header: ($) => seq(
      'new',
      'subtable',
      field('distribution', $.quoted_string),
      $._line_end,
    ),

    object_clause: ($) => seq(
      'object',
      'category',
      field('category', $.quoted_string),
      optional(seq(',', field('weights', $.comma_values))),
      $._line_end,
    ),

    equipment_entry: ($) => seq(
      $.equipment_header,
      repeat(choice(
        $.add_clause,
        $.comment,
        $._blank_line,
      )),
    ),

    equipment_header: ($) => seq(
      'new',
      'equipment',
      field('name', $.quoted_string),
      $._line_end,
    ),

    named_block: ($) => seq(
      $.named_block_header,
      repeat(choice(
        $.add_clause,
        $.comment,
        $._blank_line,
      )),
    ),

    named_block_header: ($) => seq(
      'new',
      field('kind', choice('spellset', 'itemgroup', 'namegroup')),
      field('name', $.quoted_string),
      $._line_end,
    ),

    add_clause: ($) => seq(
      'add',
      field('kind', $.identifier),
      repeat(field('qualifier', $.identifier)),
      optional(field('arguments', $.arguments)),
      $._line_end,
    ),

    generic_statement: ($) => seq(
      field('command', $.identifier),
      repeat(field('arguments', $._argument)),
      $._line_end,
    ),

    arguments: ($) => choice(
      $.quoted_string,
      $.number,
    ),

    comma_values: ($) => commaSep1(choice($.number, $.identifier, $.quoted_string)),

    _argument: ($) => choice(
      $.quoted_string,
      $.number,
      $.identifier,
      ',',
      ':',
    ),

    quoted_string: ($) => seq(
      '"',
      optional(field('content', $.string_content)),
      '"',
    ),

    string_content: () => token.immediate(prec(1, /(?:[^"\\\r\n]|\\.)+/)),

    identifier: () => token(prec(-1, /[A-Za-z_][A-Za-z0-9_.-]*/)),

    number: () => token(/-?(?:\d+(?:\.\d+)?|\.\d+)/),

    comment: ($) => seq(
      token(seq('//', /[^\r\n]*/)),
      $._line_end,
    ),

    trailing_comment: () => token(seq('//', /[^\r\n]*/)),

    _line_end: ($) => seq(
      optional($.trailing_comment),
      choice($._newline, $._eof),
    ),

    _blank_line: ($) => $._newline,
  },
});
