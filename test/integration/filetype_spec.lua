local root = assert(vim.env.BG3_TEST_ROOT, "BG3_TEST_ROOT is required")
local example = root .. "/examples/Public/Example/Stats/Generated/Data/Passive.txt"
local lsx_example = root .. "/examples/Public/Example/Progressions/Progressions.lsx"
local thoth_example = root .. "/examples/Mods/Example/Scripts/thoth/helpers/Conditions.khn"
local osiris_example = root .. "/examples/Mods/Example/Story/RawFiles/Goals/Example_Main.txt"
local localization_example = root .. "/examples/Mods/Example/Localization/English/english.xml"

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

  it("detects LSX files and uses XML buffer options", function()
    vim.cmd("edit " .. vim.fn.fnameescape(lsx_example))

    assert.equals("bg3_lsx", vim.bo.filetype)
    assert.equals("<!-- %s -->", vim.bo.commentstring)
    assert.equals("xml", vim.treesitter.language.get_lang("bg3_lsx"))
  end)

  it("detects localization XML and enables readable inline markup", function()
    vim.cmd("edit " .. vim.fn.fnameescape(localization_example))

    assert.equals("bg3_localization", vim.bo.filetype)
    assert.equals("<!-- %s -->", vim.bo.commentstring)
    assert.equals("xml", vim.treesitter.language.get_lang("bg3_localization"))
    assert.equals(2, vim.wo.conceallevel)
    assert.equals("nc", vim.wo.concealcursor)
  end)

  it("does not claim XML outside localization language directories", function()
    local buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buffer, root .. "/examples/english.xml")
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "<contentList/>" })

    assert.not_equals("bg3_localization", vim.filetype.match({ buf = buffer }))
  end)

  it("detects Thoth helper files and applies buffer options", function()
    vim.cmd("edit " .. vim.fn.fnameescape(thoth_example))

    assert.equals("bg3_thoth", vim.bo.filetype)
    assert.equals("-- %s", vim.bo.commentstring)
    assert.equals(":--", vim.bo.comments)
    assert.equals(".khn", vim.bo.suffixesadd)
  end)

  it("detects Osiris goal files and applies buffer options", function()
    vim.cmd("edit " .. vim.fn.fnameescape(osiris_example))

    assert.equals("bg3_osiris", vim.bo.filetype)
    assert.equals("// %s", vim.bo.commentstring)
    assert.equals("://,s1:/*,mb:*,ex:*/", vim.bo.comments)
    assert.equals(".txt", vim.bo.suffixesadd)
  end)

  it("does not claim ordinary text files", function()
    local buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buffer, root .. "/examples/notes.txt")
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "ordinary prose" })

    assert.not_equals("bg3_stats", vim.filetype.match({ buf = buffer }))
    assert.not_equals("bg3_osiris", vim.filetype.match({ buf = buffer }))
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
