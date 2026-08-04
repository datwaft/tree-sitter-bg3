local root = assert(vim.env.BG3_TEST_ROOT, "BG3_TEST_ROOT is required")
local example = root .. "/examples/Public/Example/Stats/Generated/Data/Passive.txt"

local function delete_buffers()
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buffer) then vim.api.nvim_buf_delete(buffer, { force = true }) end
  end
end

describe("BG3 Stats filetype", function()
  after_each(delete_buffers)

  it("detects Stats/Generated text files and applies buffer options", function()
    vim.cmd("edit " .. vim.fn.fnameescape(example))

    assert.equals("bg3_stats", vim.bo.filetype)
    assert.equals("// %s", vim.bo.commentstring)
    assert.equals("://", vim.bo.comments)
    assert.equals(".txt", vim.bo.suffixesadd)
  end)

  it("does not claim ordinary text files", function()
    local buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buffer, root .. "/examples/notes.txt")
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "ordinary prose" })

    assert.not_equals("bg3_stats", vim.filetype.match({ buf = buffer }))
  end)

  it("does not inspect BG3-looking content outside Stats/Generated", function()
    local buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buffer, root .. "/examples/outside-stats.txt")
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {
      'new entry "Outside_Stats_Generated"',
      'type "PassiveData"',
      'data "Boosts" "ActionResource(ActionPoint,1)"',
    })

    assert.not_equals("bg3_stats", vim.filetype.match({ buf = buffer }))
  end)
end)
