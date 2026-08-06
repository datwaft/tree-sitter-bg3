local root = assert(vim.env.BG3_TEST_ROOT, "BG3_TEST_ROOT is required")
local example = root .. "/examples/Public/Example/Stats/Generated/Data/Passive.txt"
local lsx_example = root .. "/examples/Public/Example/Progressions/Progressions.lsx"
local thoth_example = root .. "/examples/Mods/Example/Scripts/thoth/helpers/Conditions.khn"

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
end)
