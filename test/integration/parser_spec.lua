local root = assert(vim.env.BG3_TEST_ROOT, "BG3_TEST_ROOT is required")
local example = root .. "/examples/Public/Example/Stats/Generated/Data/Passive.txt"

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

    assert.equals(1, #trees)
    assert.is_false(trees[1]:root():has_error())
  end)

  it("loads the editor queries", function()
    open_example()

    assert.is_not_nil(vim.treesitter.query.get("bg3_stats", "highlights"))
    assert.is_not_nil(vim.treesitter.query.get("bg3_stats", "indents"))
    assert.is_not_nil(vim.treesitter.query.get("bg3_stats", "injections"))
    assert.is_not_nil(vim.treesitter.query.get("bg3_stats_value", "highlights"))
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
end)
