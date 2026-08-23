(localization_handle) @string.special
(uuid) @string.special
(dice_literal) @number
(number) @number
(boolean) @boolean
(string_literal) @string
(identifier) @variable
(ellipsis) @comment

(call_expression
  function: (identifier) @function.call)

(call_expression
  function: (member_expression
    property: (identifier) @function.method.call))

(prefixed_expression
  prefix: (identifier) @attribute)

(member_expression
  object: (identifier) @variable.builtin
  property: (identifier) @property)

((identifier) @constant
  (#match? @constant "^[A-Z][A-Z0-9_]+$"))

[
  "IF"
] @keyword.conditional

[
  "and"
  "or"
  "not"
  "!"
  "=="
  "!="
  ">="
  "<="
  ">"
  "<"
  "+"
  "-"
  "*"
  "/"
  "%"
] @operator

[
  "("
  ")"
  "{"
  "}"
  ","
  ";"
  ":"
  "."
] @punctuation.delimiter
