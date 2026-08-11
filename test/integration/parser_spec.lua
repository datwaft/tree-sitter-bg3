local root = assert(vim.env.BG3_TEST_ROOT, "BG3_TEST_ROOT is required")
local example = root .. "/examples/Public/Example/Stats/Generated/Data/Passive.txt"
local lsx_example = root .. "/examples/Public/Example/Progressions/Progressions.lsx"
local thoth_example = root .. "/examples/Mods/Example/Scripts/thoth/helpers/Conditions.khn"
local osiris_example = root .. "/examples/Mods/Example/Story/RawFiles/Goals/Example_Main.txt"
local localization_example = root .. "/examples/Mods/Example/Localization/English/english.xml"

local function open_example()
  vim.cmd("edit " .. vim.fn.fnameescape(example))
  return vim.treesitter.get_parser(0, "bg3_stats")
end

local function delete_buffers()
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buffer) then vim.api.nvim_buf_delete(buffer, { force = true }) end
  end
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

    assert.equals(4, vim.tbl_count(concealed["<"]))
    assert.equals(2, vim.tbl_count(concealed[">"]))
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
end)
