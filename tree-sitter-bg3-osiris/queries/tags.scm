(rule
  kind: ["PROC" "QRY"]
  head: (call_expression
    name: (identifier) @name)) @definition.function

(rule
  kind: "IF"
  head: (call_expression
    name: (identifier) @name)) @reference.call

(condition
  (call_expression
    name: (identifier) @name)) @reference.call

(fact_statement
  call: (call_expression
    name: (identifier) @name)) @reference.call

(action_statement
  call: (call_expression
    name: (identifier) @name)) @reference.call
