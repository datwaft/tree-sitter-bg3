[
  (do_statement)
  (while_statement)
  (repeat_statement)
  (if_statement)
  (for_statement)
  (function_declaration)
  (function_definition)
  (table_constructor)
  (try_statement)
  (arguments)
  (parameters)
  (parenthesized_expression)
  (binary_expression)
] @indent.begin

[
  "end"
  "until"
  "}"
  ")"
  "]"
  (else_statement)
  (elseif_statement)
] @indent.branch

[
  "end"
  "until"
  "}"
  ")"
  "]"
] @indent.end

(try_statement
  "catch" @indent.branch)

; Indentation evaluators only apply @indent.begin after the node's first line,
; so a binary chain broken inside parentheses would indent its continuation
; operands one level deeper than the chain head. Cancel that extra level on the
; operator token that starts each such line.
(parenthesized_expression
  (binary_expression
    operator: [
      "or" "and" "<" "<=" "==" "~=" ">=" ">" "|" "~" "&" "<<" ">>" ".." "+" "-" "*" "/" "//" "%" "^"
    ] @indent.branch))
