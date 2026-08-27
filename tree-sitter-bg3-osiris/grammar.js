/**
 * @file BG3 Osiris goal grammar
 * @author datwaft
 * @license MIT
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

const commaSep = (rule) => optional(seq(rule, repeat(seq(',', rule))));

const regularCall = ($, argumentList) => choice(
  seq(
    field('name', $.identifier),
    field('arguments', argumentList),
  ),
  seq(
    field('receiver', $.typed_variable),
    '.',
    field('name', $.identifier),
    field('arguments', argumentList),
  ),
);

export default grammar({
  name: 'bg3_osiris',

  extras: ($) => [
    /\s/,
    $.comment,
  ],

  word: ($) => $.identifier,

  rules: {
    source_file: ($) => seq(
      choice(
        seq(
          $.version_declaration,
          $.subgoal_combiner_declaration,
          $.init_section,
          $.kb_section,
          $.exit_section,
          repeat($.parent_target_edge),
        ),
        $.callable_signature,
      ),
    ),

    callable_signature: ($) => seq(
      field('name', $.identifier),
      field('arguments', $.signature_argument_list),
    ),

    signature_argument_list: ($) => seq(
      '(',
      commaSep($.signature_parameter),
      ')',
    ),

    signature_parameter: ($) => seq(
      field('direction', $.parameter_direction),
      field('type', $.identifier),
      field('name', $.local_variable),
    ),

    parameter_direction: () => choice(
      '[in]',
      '[out]',
      '[inout]',
    ),

    version_declaration: ($) => seq(
      'Version',
      field('value', $.integer),
    ),

    subgoal_combiner_declaration: () => seq(
      'SubGoalCombiner',
      'SGC_AND',
    ),

    init_section: ($) => seq(
      'INITSECTION',
      repeat(field('statement', $._fact)),
    ),

    kb_section: ($) => seq(
      'KBSECTION',
      repeat(field('rule', $.rule)),
    ),

    exit_section: ($) => seq(
      'EXITSECTION',
      repeat(field('statement', $._fact)),
      'ENDEXITSECTION',
    ),

    parent_target_edge: ($) => seq(
      'ParentTargetEdge',
      field('goal', $.string_literal),
    ),

    _fact: ($) => choice(
      $.fact_statement,
      $.goal_completed_statement,
    ),

    fact_statement: ($) => seq(
      optional(field('negation', 'NOT')),
      field('call', alias($._fact_call_expression, $.call_expression)),
      ';',
    ),

    _fact_call_expression: ($) => seq(
      field('name', $.identifier),
      field('arguments', alias($._fact_argument_list, $.argument_list)),
    ),

    _fact_argument_list: ($) => seq(
      '(',
      commaSep($.typed_constant),
      ')',
    ),

    rule: ($) => seq(
      field('kind', choice('IF', 'PROC', 'QRY')),
      field('head', $.call_expression),
      repeat(seq(
        'AND',
        field('condition', $.condition),
      )),
      'THEN',
      repeat1(field('action', $._action)),
    ),

    condition: ($) => seq(
      optional(field('negation', 'NOT')),
      choice(
        $.call_expression,
        $.comparison_expression,
      ),
    ),

    comparison_expression: ($) => seq(
      field('left', $._value),
      field('operator', $.comparison_operator),
      field('right', $._value),
    ),

    comparison_operator: () => choice(
      '==',
      '!=',
      '<',
      '<=',
      '>',
      '>=',
    ),

    _action: ($) => choice(
      $.action_statement,
      $.goal_completed_statement,
    ),

    action_statement: ($) => seq(
      optional(field('negation', 'NOT')),
      field('call', $.call_expression),
      ';',
    ),

    goal_completed_statement: () => seq(
      'GoalCompleted',
      ';',
    ),

    call_expression: ($) => regularCall($, $.argument_list),

    argument_list: ($) => seq(
      '(',
      commaSep($._value),
      ')',
    ),

    _value: ($) => choice(
      $.typed_variable,
      $.typed_constant,
    ),

    typed_variable: ($) => seq(
      optional(field('cast', $.type_cast)),
      field('value', choice(
        $.local_variable,
        $.anonymous_variable,
      )),
    ),

    typed_constant: ($) => seq(
      optional(field('cast', $.type_cast)),
      field('value', $._constant),
    ),

    type_cast: ($) => seq(
      '(',
      field('type', $.identifier),
      ')',
    ),

    _constant: ($) => choice(
      $.string_literal,
      $.guid_literal,
      $.real,
      $.integer,
    ),

    string_literal: ($) => seq(
      optional('L'),
      '"',
      optional(field('content', $.string_content)),
      '"',
    ),

    string_content: () => token.immediate(prec(1, /(?:[^"\\\r\n]|\\.)+/)),

    guid_literal: () => token(prec(2, choice(
      /[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/,
      /[A-Za-z][A-Za-z0-9_-]*[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/,
    ))),

    real: () => token(prec(1, /[+-]?\d+\.\d+/)),

    integer: () => token(/[+-]?\d+/),

    anonymous_variable: () => '_',

    local_variable: () => /_[A-Za-z0-9_]+/,

    identifier: () => /[A-Za-z][A-Za-z0-9_]*/,

    comment: () => token(choice(
      seq('//', /[^\r\n]*/),
      seq('/*', /[^*]*\*+([^/*][^*]*\*+)*/, '/'),
    )),
  },
});
