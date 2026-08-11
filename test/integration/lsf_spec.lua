local root = assert(vim.env.BG3_TEST_ROOT, "BG3_TEST_ROOT is required")
local converter = root .. "/test/fixtures/mock-bg3-ls"
local directories = {}

local function delete_buffers()
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buffer) then vim.api.nvim_buf_delete(buffer, { force = true }) end
  end
end

local function fixture()
  local directory = vim.fn.tempname() .. " with spaces;literal"
  vim.fn.mkdir(directory, "p")
  table.insert(directories, directory)
  local path = directory .. "/metadata.lsf"
  vim.fn.writefile({ "LSOForiginal" }, path, "b")
  vim.uv.fs_chmod(path, 416) -- 0640
  vim.g.bg3_lsf_converter = converter
  return path
end

local function contents(path)
  local file = assert(io.open(path, "rb"))
  local bytes = file:read("*a")
  file:close()
  return bytes
end

describe("transparent BG3 LSF editing", function()
  after_each(function()
    delete_buffers()
    vim.g.bg3_lsf_converter = nil
    for _, directory in ipairs(directories) do
      vim.fn.delete(directory, "rf")
    end
    directories = {}
  end)

  it("opens LSX text and atomically saves compiled LSF", function()
    local path = fixture()
    vim.cmd("edit " .. vim.fn.fnameescape(path))

    assert.equals("bg3_lsf", vim.bo.filetype)
    assert.equals("acwrite", vim.bo.buftype)
    assert.equals("xml", vim.treesitter.language.get_lang("bg3_lsf"))
    assert.is_not_nil(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()])
    assert.is_truthy(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"):find("<save>", 1, true))

    local writes = 0
    vim.api.nvim_create_autocmd("BufWritePost", {
      buffer = 0,
      callback = function() writes = writes + 1 end,
    })
    vim.api.nvim_buf_set_lines(0, -1, -1, false, { "<!-- edited -->" })
    vim.cmd("write")

    assert.equals("LSOF", contents(path):sub(1, 4))
    assert.is_truthy(contents(path):find("edited", 1, true))
    assert.equals(416, vim.uv.fs_stat(path).mode % 512)
    assert.equals(1, writes)
    assert.is_false(vim.bo.modified)
  end)

  it("keeps the source and modified buffer after conversion failure", function()
    local path = fixture()
    local original = contents(path)
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    vim.api.nvim_buf_set_lines(0, -1, -1, false, { "INVALID" })

    local success, message = pcall(vim.cmd, "write")

    assert.is_false(success)
    assert.is_truthy(tostring(message):find("synthetic conversion failure", 1, true), tostring(message))
    assert.equals(original, contents(path))
    assert.is_true(vim.bo.modified)
  end)

  it("refuses to overwrite a file changed outside Neovim", function()
    local path = fixture()
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    vim.api.nvim_buf_set_lines(0, -1, -1, false, { "<!-- edited -->" })
    vim.fn.writefile({ "EXTERNAL" }, path, "b")

    local success, message = pcall(vim.cmd, "write")

    assert.is_false(success)
    assert.is_truthy(tostring(message):find("file changed on disk", 1, true))
    assert.equals("EXTERNAL", contents(path))
    assert.is_true(vim.bo.modified)
  end)

  it("reports an unavailable converter without reading binary text", function()
    local path = fixture()
    vim.g.bg3_lsf_converter = "/does/not/exist/bg3-ls"

    local success, message = pcall(vim.cmd, "edit " .. vim.fn.fnameescape(path))

    assert.is_false(success)
    assert.is_truthy(tostring(message):find("converter is not executable", 1, true))
    assert.same({ "" }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
  end)
end)
