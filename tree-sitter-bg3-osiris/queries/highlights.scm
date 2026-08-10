(comment) @comment

[
  "Version"
  "SubGoalCombiner"
  "SGC_AND"
  "ParentTargetEdge"
] @keyword.directive

[
  "INITSECTION"
  "KBSECTION"
  "EXITSECTION"
  "ENDEXITSECTION"
] @keyword

[
  "IF"
  "PROC"
  "QRY"
  "AND"
  "THEN"
  "NOT"
] @keyword.control

"GoalCompleted" @function.builtin

(identifier) @variable
(local_variable) @variable
(anonymous_variable) @variable.builtin

(type_cast
  type: (identifier) @type)

(rule
  kind: ["PROC" "QRY"]
  head: (call_expression
    name: (identifier) @function))

(call_expression
  name: (identifier) @function.call)

((identifier) @variable.special
  (#match? @variable.special "^DB_"))

(string_literal) @string
(guid_literal) @string.special
(integer) @number
(real) @number.float

(comparison_operator) @operator

[
  "("
  ")"
  ","
  ";"
  "."
] @punctuation.delimiter
