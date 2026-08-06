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
] @indent.begin

[
  "end"
  "until"
  "}"
] @indent.end

[
  (else_statement)
  (elseif_statement)
] @indent.branch

(try_statement
  "catch" @indent.branch)
