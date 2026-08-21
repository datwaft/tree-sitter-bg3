const PREC = {
  OR: 1,
  AND: 2,
  COMPARE: 3,
  ADD: 4,
  MULTIPLY: 5,
  UNARY: 6,
  RESOURCE: 7,
  MEMBER: 8,
  CALL: 9,
};

const BINARY_OPERATORS = {
  or: PREC.OR,
  and: PREC.AND,
  '==': PREC.COMPARE,
  '!=': PREC.COMPARE,
  '>=': PREC.COMPARE,
  '<=': PREC.COMPARE,
  '>': PREC.COMPARE,
  '<': PREC.COMPARE,
  '+': PREC.ADD,
  '-': PREC.ADD,
  '*': PREC.MULTIPLY,
  '/': PREC.MULTIPLY,
  '%': PREC.MULTIPLY,
};

export default grammar({
  name: 'bg3_stats_value',

  extras: () => [/\s/],

  word: ($) => $.identifier,

  rules: {
    source_file: ($) => optional($.sequence),

    sequence: ($) => prec.right(seq(
      $._sequence_element,
      repeat(seq(';', $._sequence_element)),
      optional(';'),
    )),

    _sequence_element: ($) => choice($.expression, $.ellipsis),

    ellipsis: () => '…',

    expression: ($) => choice(
      $.if_expression,
      $.binary_expression,
      $.unary_expression,
      $.call_expression,
      $.member_expression,
      $.resource_expression,
      $.parenthesized_expression,
      $.list_literal,
      $.string_literal,
      $.uuid,
      $.localization_handle,
      $.dice_literal,
      $.number,
      $.boolean,
      $.identifier,
    ),

    if_expression: ($) => prec.right(seq(
      'IF',
      '(',
      field('condition', $.expression),
      ')',
      ':',
      field('consequence', $.expression),
    )),

    binary_expression: ($) => choice(
      ...Object.entries(BINARY_OPERATORS).map(([operator, precedence]) => prec.left(precedence, seq(
        field('left', $.expression),
        field('operator', operator),
        field('right', $.expression),
      ))),
    ),

    unary_expression: ($) => prec(PREC.UNARY, seq(
      field('operator', choice('not', '!', '-')),
      field('argument', $.expression),
    )),

    call_expression: ($) => prec(PREC.CALL, seq(
      field('function', choice($.identifier, $.member_expression)),
      field('arguments', $.argument_list),
    )),

    argument_list: ($) => seq('(', optional($._expression_list), ')'),

    _expression_list: ($) => seq(
      choice($.expression, $.ellipsis),
      repeat(seq(',', choice($.expression, $.ellipsis))),
      optional(','),
    ),

    member_expression: ($) => prec.left(PREC.MEMBER, seq(
      field('object', choice($.identifier, $.member_expression)),
      '.',
      field('property', $.identifier),
    )),

    resource_expression: ($) => prec.right(PREC.RESOURCE, seq(
      field('resource', $.identifier),
      repeat1(seq(':', field('amount', choice($.number, $.dice_literal, $.identifier)))),
    )),

    parenthesized_expression: ($) => seq('(', $.expression, ')'),

    list_literal: ($) => seq('{', optional($._expression_list), '}'),

    string_literal: ($) => seq(
      "'",
      optional($.string_content),
      "'",
    ),

    string_content: () => token.immediate(/(?:[^'\\]|\\.)+/),

    uuid: () => token(prec(3, /[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/)),

    localization_handle: () => token(prec(3, /h[0-9A-Za-z]{36}/)),

    dice_literal: () => token(prec(2, /\d+d(?:4|6|8|10|12|20|100)/)),

    number: () => token(/(?:\d+(?:\.\d+)?|\.\d+)/),

    boolean: () => choice('true', 'false', 'True', 'False'),

    identifier: () => /[A-Za-z_][A-Za-z0-9_]*/,
  },
});
