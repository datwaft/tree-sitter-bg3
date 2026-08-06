; inherits: lua

(try_statement
  [
    "try"
    "catch"
    "then"
    "end"
  ] @keyword.exception
  error: (identifier) @variable.parameter)

((identifier) @variable.builtin
  (#eq? @variable.builtin "context"))

((identifier) @module.builtin
  (#any-of? @module.builtin "ls" "math"))
