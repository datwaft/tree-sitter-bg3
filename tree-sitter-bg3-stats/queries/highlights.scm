(comment) @comment
(trailing_comment) @comment

[
  "new"
  "entry"
  "type"
  "using"
  "data"
  "treasuretable"
  "subtable"
  "equipment"
  "spellset"
  "itemgroup"
  "namegroup"
  "add"
  "object"
  "category"
] @keyword

(quoted_string) @string
(number) @number
(identifier) @variable

(entry_header
  name: (quoted_string (string_content) @type.definition))

(type_clause
  value: (quoted_string (string_content) @type))

(using_clause
  value: (quoted_string (string_content) @type))

(data_clause
  name: (quoted_string (string_content) @property))

(data_clause
  value: (quoted_string (string_content) @string))

(treasure_table_header
  name: (quoted_string (string_content) @type.definition))

(equipment_header
  name: (quoted_string (string_content) @type.definition))

(named_block_header
  name: (quoted_string (string_content) @type.definition))

(object_clause
  category: (quoted_string (string_content) @constant))

[
  "\""
  ","
  ":"
] @punctuation.delimiter
