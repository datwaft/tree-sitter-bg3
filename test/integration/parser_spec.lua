local root = assert(vim.env.BG3_TEST_ROOT, "BG3_TEST_ROOT is required")
local example = root .. "/examples/Public/Example/Stats/Generated/Data/Passive.txt"
local lsx_example = root .. "/examples/Public/Example/Progressions/Progressions.lsx"
local thoth_example = root .. "/examples/Mods/Example/Scripts/thoth/helpers/Conditions.khn"
local osiris_example = root .. "/examples/Mods/Example/Story/RawFiles/Goals/Example_Main.txt"
local localization_example = root .. "/examples/Mods/Example/Localization/English/english.xml"
local osiris_indent_fixtures = root .. "/test/fixtures/Story/RawFiles/Goals/"
local thoth_indent_fixtures = root .. "/test/fixtures/Mods/Example/Scripts/thoth/helpers/"

local function open_example()
  vim.cmd("edit " .. vim.fn.fnameescape(example))
  return vim.treesitter.get_parser(0, "bg3_stats")
end

local function delete_buffers()
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buffer) then vim.api.nvim_buf_delete(buffer, { force = true }) end
  end
end

local function osiris_indentexpr()
  local line = vim.v.lnum - 1
  local parser = vim.treesitter.get_parser(0, "bg3_osiris")
  local tree = assert(parser:parse(true)[1], "expected an Osiris syntax tree")
  local query = assert(vim.treesitter.query.get("bg3_osiris", "indents"))
  local indent = 0

  for capture, node in query:iter_captures(tree:root(), 0) do
    local name = query.captures[capture]
    local start_row, _, end_row = node:range()
    if name == "indent.begin" and start_row < line and line <= end_row then
      indent = indent + vim.fn.shiftwidth()
    elseif name == "indent.branch" and start_row == line then
      indent = indent - vim.fn.shiftwidth()
    end
  end

  return indent
end

_G.bg3_test_osiris_indentexpr = osiris_indentexpr

local function assert_osiris_reindent_round_trip(name)
  vim.cmd("edit " .. vim.fn.fnameescape(osiris_indent_fixtures .. name))
  local expected = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local unindented = vim.tbl_map(function(line) return (line:gsub("^%s+", "")) end, expected)

  vim.api.nvim_buf_set_lines(0, 0, -1, false, unindented)
  vim.bo.expandtab = true
  vim.bo.shiftwidth = 2
  vim.bo.indentexpr = "v:lua.bg3_test_osiris_indentexpr()"
  vim.cmd("normal! gg=G")

  assert.same(expected, vim.api.nvim_buf_get_lines(0, 0, -1, false))
end

-- Mirrors the @indent.begin/@indent.branch/@indent.dedent semantics of the
-- tree-sitter indentation evaluators Neovim ecosystem plugins run (arborist,
-- former nvim-treesitter indent): begin adds one level after the node's first
-- line, branch removes one level on the node's own line, dedent removes one
-- level on lines after the node's first line, and one adjustment per start row
-- wins. Empty lines are never reindented by `=`.
local function thoth_indentexpr()
  local lnum = vim.v.lnum
  local parser = vim.treesitter.get_parser(0, "bg3_thoth")
  local tree = assert(parser:parse(true)[1], "expected a Thoth syntax tree")
  local query = assert(vim.treesitter.query.get("bg3_thoth", "indents"))

  local captures = {}
  for capture, node in query:iter_captures(tree:root(), 0) do
    local id = node:id()
    captures[id] = captures[id] or {}
    captures[id][query.captures[capture]] = true
  end

  local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ""
  local _, column = line:find("^%s*")
  local node = tree:root():descendant_for_range(lnum - 1, column, lnum - 1, column + 1)

  local indent, seen = 0, {}
  while node do
    local start_row, _, end_row = node:range()
    local node_captures = captures[node:id()]
    if node_captures and not seen[start_row] then
      local applied = false
      if node_captures["indent.branch"] and start_row == lnum - 1 then
        indent = indent - vim.fn.shiftwidth()
        applied = true
      end
      if node_captures["indent.dedent"] and start_row ~= lnum - 1 then
        indent = indent - vim.fn.shiftwidth()
        applied = true
      end
      local parent_in_error = node:parent() and node:parent():has_error()
      if node_captures["indent.begin"] and (start_row ~= end_row or parent_in_error) and start_row ~= lnum - 1 then
        indent = indent + vim.fn.shiftwidth()
        applied = true
      end
      if applied then seen[start_row] = true end
    end
    node = node:parent()
  end

  return indent
end

_G.bg3_test_thoth_indentexpr = thoth_indentexpr

local function assert_thoth_reindent_round_trip(name)
  vim.cmd("edit " .. vim.fn.fnameescape(thoth_indent_fixtures .. name))
  local expected = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local unindented = vim.tbl_map(function(line) return (line:gsub("^%s+", "")) end, expected)

  vim.api.nvim_buf_set_lines(0, 0, -1, false, unindented)
  vim.bo.expandtab = true
  vim.bo.shiftwidth = 2
  vim.bo.indentexpr = "v:lua.bg3_test_thoth_indentexpr()"
  vim.cmd("normal! gg=G")

  assert.same(expected, vim.api.nvim_buf_get_lines(0, 0, -1, false))
end

describe("BG3 Stats parser integration", function()
  after_each(delete_buffers)

  it("parses the outer Stats document", function()
    local trees = open_example():parse(true)
    local tree = assert(trees[1], "expected an outer syntax tree")

    assert.equals(1, #trees)
    assert.is_false(tree:root():has_error())
  end)

  it("loads the editor queries", function()
    open_example()

    assert.is_not_nil(vim.treesitter.query.get("bg3_stats", "highlights"))
    assert.is_not_nil(vim.treesitter.query.get("bg3_stats", "indents"))
    assert.is_not_nil(vim.treesitter.query.get("bg3_stats", "injections"))
    assert.is_not_nil(vim.treesitter.query.get("bg3_stats_value", "highlights"))
    assert.is_not_nil(vim.treesitter.query.get("bg3_thoth", "highlights"))
    assert.is_not_nil(vim.treesitter.query.get("bg3_thoth", "indents"))
    assert.is_not_nil(vim.treesitter.query.get("bg3_thoth", "folds"))
    assert.is_not_nil(vim.treesitter.query.get("bg3_thoth", "locals"))
    assert.is_not_nil(vim.treesitter.query.get("bg3_thoth", "tags"))
    assert.is_not_nil(vim.treesitter.query.get("bg3_osiris", "highlights"))
    assert.is_not_nil(vim.treesitter.query.get("bg3_osiris", "indents"))
    assert.is_not_nil(vim.treesitter.query.get("bg3_osiris", "folds"))
    assert.is_not_nil(vim.treesitter.query.get("bg3_osiris", "tags"))
  end)

  it("parses Thoth helpers and exception handling", function()
    vim.cmd("edit " .. vim.fn.fnameescape(thoth_example))
    local trees = vim.treesitter.get_parser(0, "bg3_thoth"):parse(true)
    local tree = assert(trees[1], "expected a Thoth syntax tree")

    assert.equals(1, #trees)
    assert.is_false(tree:root():has_error())

    local query = vim.treesitter.query.parse("bg3_thoth", "(try_statement) @exception")
    local exceptions = 0
    for _, _ in query:iter_captures(tree:root(), 0) do
      exceptions = exceptions + 1
    end
    assert.equals(1, exceptions)
  end)

  it("parses Osiris goals and exposes fold and tag captures", function()
    vim.cmd("edit " .. vim.fn.fnameescape(osiris_example))
    local trees = vim.treesitter.get_parser(0, "bg3_osiris"):parse(true)
    local tree = assert(trees[1], "expected an Osiris syntax tree")

    assert.equals(1, #trees)
    assert.is_false(tree:root():has_error())

    local folds = assert(vim.treesitter.query.get("bg3_osiris", "folds"))
    local fold_count = 0
    for _, _ in folds:iter_captures(tree:root(), 0) do
      fold_count = fold_count + 1
    end
    assert.is_true(fold_count >= 4)

    local tags = assert(vim.treesitter.query.get("bg3_osiris", "tags"))
    local definitions = 0
    local references = 0
    for capture in tags:iter_captures(tree:root(), 0) do
      local name = tags.captures[capture]
      if name == "definition.function" then definitions = definitions + 1 end
      if name == "reference.call" then references = references + 1 end
    end
    assert.equals(2, definitions)
    assert.is_true(references > 0)
  end)

  it(
    "reindents the complete Osiris goal structure",
    function() assert_osiris_reindent_round_trip("indent_complete.txt") end
  )

  it(
    "reindents the complete Thoth helper structure",
    function() assert_thoth_reindent_round_trip("indent_complete.khn") end
  )

  it(
    "keeps empty Osiris section directives at column zero",
    function() assert_osiris_reindent_round_trip("indent_empty.txt") end
  )

  it("parses injected data values with the value grammar", function()
    local parser = open_example()
    parser:parse(true)
    local injected = false

    parser:for_each_tree(function(tree, language_tree)
      if language_tree:lang() == "bg3_stats_value" then
        injected = true
        assert.is_false(tree:root():has_error())
      end
    end)

    assert.is_true(injected)
  end)

  it("parses injected LSX values with the value grammar", function()
    vim.cmd("edit " .. vim.fn.fnameescape(lsx_example))
    local parser = vim.treesitter.get_parser(0)
    parser:parse(true)
    local injections = {}

    parser:for_each_tree(function(tree, language_tree)
      if language_tree:lang() == "bg3_stats_value" then
        assert.is_false(tree:root():has_error())
        injections[vim.treesitter.get_node_text(tree:root(), 0)] = true
      end
    end)

    assert.is_true(injections["ActionResource(SpellSlot,1,1);Proficiency(LightArmor)"])
    assert.is_true(injections["SelectSpells(11111111-1111-1111-1111-111111111111,1,0)"])
    assert.is_nil(injections.TestProgression)
  end)

  it("conceals escaped localization delimiters and leaves literal greater-than signs", function()
    vim.cmd("edit " .. vim.fn.fnameescape(localization_example))
    local tree = assert(vim.treesitter.get_parser(0, "xml"):parse(true)[1])
    local query = assert(vim.treesitter.query.get("xml", "highlights"))
    local concealed = { ["<"] = {}, [">"] = {} }

    for _, match, metadata in query:iter_matches(tree:root(), 0, 0, -1, { all = true }) do
      for capture, nodes in pairs(match) do
        local capture_metadata = metadata[capture]
        if capture_metadata and capture_metadata.conceal then
          if query.captures[capture] == "conceal" then
            for _, node in ipairs(nodes) do
              local row, column, end_row, end_column = node:range()
              local position = table.concat({ row, column, end_row, end_column }, ":")
              concealed[capture_metadata.conceal][position] = vim.treesitter.get_node_text(node, 0)
            end
          end
        end
      end
    end

    assert.equals(5, vim.tbl_count(concealed["<"]))
    assert.equals(3, vim.tbl_count(concealed[">"]))
    for _, entity in pairs(concealed["<"]) do
      assert.equals("&lt;", entity)
    end
    for _, entity in pairs(concealed[">"]) do
      assert.equals("&gt;", entity)
    end
    local source = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    assert.is_truthy(source:find('Tooltip="Literal">', 1, true))
    assert.is_truthy(source:find("Comparison: 3 > 2", 1, true))
    assert.is_truthy(source:find("<metadata>&lt;Outside&gt;</metadata>", 1, true))

    for column = 3, 9 do
      local inspected = vim.inspect_pos(0, 2, column, { treesitter = true, syntax = false, extmarks = false })
      for _, capture in ipairs(inspected.treesitter) do
        local capture_metadata = capture.metadata[capture.id] or {}
        assert.is_nil(capture_metadata.conceal, "outer content tag must not be concealed")
      end
    end
  end)

  it("highlights encoded and literal LSTag markup independently from prose", function()
    vim.cmd("edit " .. vim.fn.fnameescape(localization_example))

    local function extmark_groups(row, column)
      local inspected = vim.inspect_pos(0, row, column, { treesitter = false, syntax = false, extmarks = true })
      local groups = {}
      for _, extmark in ipairs(inspected.extmarks) do
        if extmark.opts.hl_group then groups[extmark.opts.hl_group] = true end
      end
      return groups
    end

    local encoded = vim.api.nvim_buf_get_lines(0, 2, 3, false)[1]
    local encoded_name = assert(encoded:find("LSTag", 1, true)) - 1
    local encoded_attribute = assert(encoded:find("Tooltip", 1, true)) - 1
    local encoded_value = assert(encoded:find('"Escaped"', 1, true)) - 1
    assert.is_true(extmark_groups(2, encoded_name)["@tag"])
    assert.is_true(extmark_groups(2, encoded_attribute)["@tag.attribute"])
    assert.is_true(extmark_groups(2, encoded_value)["@string.special"])

    local literal = vim.api.nvim_buf_get_lines(0, 3, 4, false)[1]
    local literal_name = assert(literal:find("LSTag", 1, true)) - 1
    local literal_attribute = assert(literal:find("Tooltip", 1, true)) - 1
    assert.is_true(extmark_groups(3, literal_name)["@tag"])
    assert.is_true(extmark_groups(3, literal_attribute)["@tag.attribute"])

    vim.api.nvim_buf_set_lines(0, 3, 4, false, { "  <content>plain text</content>" })
    assert.is_nil(extmark_groups(3, 12)["@tag"])
  end)

  it("highlights Type attributes and inline br markup like Tooltip", function()
    vim.cmd("edit " .. vim.fn.fnameescape(localization_example))

    local function extmark_groups(row, column)
      local inspected = vim.inspect_pos(0, row, column, { treesitter = false, syntax = false, extmarks = true })
      local groups = {}
      for _, extmark in ipairs(inspected.extmarks) do
        if extmark.opts.hl_group then groups[extmark.opts.hl_group] = true end
      end
      return groups
    end

    -- Row 4 carries literal markup: Type, Tooltip, <br>, and <br/>.
    local typed = vim.api.nvim_buf_get_lines(0, 4, 5, false)[1]
    assert.is_truthy(typed:find('<LSTag Type="ActionResource"', 1, true))
    assert.is_true(extmark_groups(4, typed:find("Type", 1, true) - 1)["@tag.attribute"])
    assert.is_true(extmark_groups(4, typed:find('"ActionResource"', 1, true) - 1)["@string.special"])
    assert.is_true(extmark_groups(4, typed:find("Tooltip", 1, true) - 1)["@tag.attribute"])
    assert.is_true(extmark_groups(4, typed:find('"BonusActionPoint"', 1, true) - 1)["@string.special"])

    -- Row 5 carries the bare literal form through a scratch-free case; here
    -- the fixture keeps XML well-formed with a self-closing tag.
    local closing = typed:find("<br/>", 1, true)
    assert.is_true(extmark_groups(4, closing - 1)["@punctuation.bracket"])
    assert.is_true(extmark_groups(4, closing + 1)["@tag"])
    assert.is_true(extmark_groups(4, closing + 2)["@tag"])
    assert.is_true(extmark_groups(4, closing + 3)["@punctuation.bracket"])

    -- Row 5 carries encoded inline markup.
    local encoded = vim.api.nvim_buf_get_lines(0, 5, 6, false)[1]
    local entity = assert(encoded:find("&lt;br&gt;", 1, true))
    assert.is_true(extmark_groups(5, entity - 1)["@punctuation.bracket"])
    assert.is_true(extmark_groups(5, entity + 3)["@tag"])
    assert.is_true(extmark_groups(5, entity + 8)["@punctuation.bracket"])
  end)

  it("highlights bare br tags in scratch buffers without XML well-formedness", function()
    local buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "A<br>B and &lt;br/&gt; C" })
    vim.api.nvim_set_current_buf(buffer)
    vim.bo[buffer].filetype = "bg3_localization"
    vim.wait(50)

    local function group_at(row, column)
      local inspected = vim.inspect_pos(0, row, column, { treesitter = false, syntax = false, extmarks = true })
      for _, extmark in ipairs(inspected.extmarks) do
        if extmark.opts.hl_group then return extmark.opts.hl_group end
      end
      return nil
    end

    local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
    local literal_br = line:find("<br>", 1, true)
    assert.equals("@punctuation.bracket", group_at(0, literal_br - 1))
    assert.equals("@tag", group_at(0, literal_br))
    assert.equals("@punctuation.bracket", group_at(0, literal_br + 2))

    local encoded_self_closing = assert(line:find("&lt;br/&gt;", 1, true))
    assert.equals("@punctuation.bracket", group_at(0, encoded_self_closing - 1))
    assert.equals("@tag", group_at(0, encoded_self_closing + 3))
    assert.equals("@tag", group_at(0, encoded_self_closing + 4))
    assert.equals("@tag", group_at(0, encoded_self_closing + 5))
    assert.equals("@punctuation.bracket", group_at(0, encoded_self_closing + 6))
  end)
end)

describe("BG3 Osiris highlights query", function()
  it("captures stable editor groups across goal structure", function()
    vim.cmd("edit " .. vim.fn.fnameescape(osiris_example))
    local parser = vim.treesitter.get_parser(0, "bg3_osiris")
    local tree = assert(parser:parse(true)[1], "expected an Osiris syntax tree")
    local query = assert(vim.treesitter.query.get("bg3_osiris", "highlights"))

    local captured = {}
    for id, node in query:iter_captures(tree:root(), 0) do
      local name = query.captures[id]
      captured[name] = captured[name] or {}
      table.insert(captured[name], vim.treesitter.get_node_text(node, 0))
    end

    local function contains(group, text)
      for _, value in ipairs(captured[group] or {}) do
        if value == text then return true end
      end
      return false
    end

    assert.is_true(contains("keyword", "INITSECTION"))
    assert.is_true(contains("keyword", "EXITSECTION"))
    assert.is_true(contains("keyword.control", "IF"))
    assert.is_true(contains("keyword.control", "THEN"))
    assert.is_true(contains("type", "CHARACTER"))
    assert.is_true(contains("function", "QRY_Example_IsReady"))
    assert.is_true(contains("function.call", "ExampleEvent"))
    assert.is_true(contains("variable.special", "DB_Example_Seen"))
    assert.is_true(contains("string", '"Example_Parent"'))
    assert.is_true(contains("number", "1"))
  end)

  it("highlights standalone callable signatures", function()
    local buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buffer)
    vim.bo[buffer].filetype = "bg3_osiris"
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {
      "Example([in] INTEGER _Input, [out] REAL _Output, [inout] STRING _Value)",
    })

    local parser = vim.treesitter.get_parser(buffer, "bg3_osiris")
    local tree = assert(parser:parse(true)[1], "expected a signature syntax tree")
    assert.is_false(tree:root():has_error())

    local query = assert(vim.treesitter.query.get("bg3_osiris", "highlights"))
    local captured = {}
    for id, node in query:iter_captures(tree:root(), buffer) do
      local name = query.captures[id]
      captured[name] = captured[name] or {}
      table.insert(captured[name], vim.treesitter.get_node_text(node, buffer))
    end

    local function contains(group, text)
      for _, value in ipairs(captured[group] or {}) do
        if value == text then return true end
      end
      return false
    end

    assert.is_true(contains("keyword.modifier", "[in]"))
    assert.is_true(contains("keyword.modifier", "[out]"))
    assert.is_true(contains("keyword.modifier", "[inout]"))
    assert.is_true(contains("type", "INTEGER"))
    assert.is_true(contains("type", "REAL"))
    assert.is_true(contains("type", "STRING"))
    assert.is_true(contains("variable", "_Input"))
    assert.is_true(contains("variable", "_Output"))
    assert.is_true(contains("variable", "_Value"))

    vim.api.nvim_buf_delete(buffer, { force = true })
  end)
end)
