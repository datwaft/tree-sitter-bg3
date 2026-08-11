local M = {}

local states = {}

local function converter_command()
  local configured = vim.g.bg3_lsf_converter
  if configured == nil then return { "bg3-ls" } end
  if type(configured) == "string" then return { configured } end
  if type(configured) == "table" and #configured > 0 then return vim.deepcopy(configured) end
  error("bg3-lsf: vim.g.bg3_lsf_converter must be a command string or argument list", 0)
end

local function conversion_command(source, destination)
  local command = converter_command()
  if vim.fn.executable(command[1]) ~= 1 then error("bg3-lsf: converter is not executable: " .. command[1], 0) end
  vim.list_extend(command, { "convert", source, destination })
  return command
end

local function run_conversion(source, destination)
  return vim.system(conversion_command(source, destination), { text = true }):wait()
end

local function conversion_error(action, result)
  local detail = vim.trim(result.stderr or "")
  if detail == "" then detail = "converter exited with status " .. result.code end
  error("bg3-lsf: could not " .. action .. ": " .. detail, 0)
end

local function unlink(path)
  local success, error_message, error_name = vim.uv.fs_unlink(path)
  if not success and error_name ~= "ENOENT" then
    error("bg3-lsf: could not remove temporary file: " .. error_message, 0)
  end
end

local function fingerprint(path)
  local stat, error_message, error_name = vim.uv.fs_stat(path)
  if not stat then error("bg3-lsf: could not inspect " .. path .. ": " .. (error_message or error_name), 0) end
  return {
    dev = stat.dev,
    ino = stat.ino,
    size = stat.size,
    mtime_sec = stat.mtime.sec,
    mtime_nsec = stat.mtime.nsec,
    mode = stat.mode,
  }
end

local function same_file(left, right)
  return left.dev == right.dev
    and left.ino == right.ino
    and left.size == right.size
    and left.mtime_sec == right.mtime_sec
    and left.mtime_nsec == right.mtime_nsec
end

local function assert_unchanged(state)
  if not same_file(state.fingerprint, fingerprint(state.path)) then
    error("bg3-lsf: file changed on disk; use :edit! to reload before saving", 0)
  end
end

local function sibling_temporary(path)
  local directory = vim.fs.dirname(path)
  local name = vim.fs.basename(path)
  return string.format("%s/.%s.bg3-lsf-%d-%s.lsf", directory, name, vim.uv.os_getpid(), tostring(vim.uv.hrtime()))
end

local function read_lsof_signature(path)
  local file, open_error = io.open(path, "rb")
  if not file then error("bg3-lsf: could not verify converted output: " .. open_error, 0) end
  local signature = file:read(4)
  file:close()
  return signature
end

local function write_buffer(buffer, path)
  local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
  local result = vim.fn.writefile(lines, path, "b")
  if result ~= 0 then error("bg3-lsf: could not write temporary LSX input", 0) end
end

local function read(buffer, path)
  local temporary = vim.fn.tempname() .. ".lsx"
  local result = run_conversion(path, temporary)
  if result.code ~= 0 then
    unlink(temporary)
    conversion_error("decompile LSF", result)
  end

  local lines = vim.fn.readfile(temporary, "b")
  unlink(temporary)
  vim.bo[buffer].modifiable = true
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  vim.bo[buffer].buftype = "acwrite"
  vim.bo[buffer].filetype = "bg3_lsf"
  vim.bo[buffer].modified = false

  states[buffer] = {
    path = path,
    fingerprint = fingerprint(path),
  }

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buffer,
    callback = function() M.write(buffer) end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buffer,
    once = true,
    callback = function() states[buffer] = nil end,
  })
end

function M.write(buffer)
  local state = assert(states[buffer], "bg3-lsf: buffer has no source state")
  assert_unchanged(state)
  vim.api.nvim_exec_autocmds("BufWritePre", { buffer = buffer, modeline = false })

  local temporary_lsx = vim.fn.tempname() .. ".lsx"
  local temporary_lsf = sibling_temporary(state.path)
  write_buffer(buffer, temporary_lsx)
  local result = run_conversion(temporary_lsx, temporary_lsf)
  unlink(temporary_lsx)
  if result.code ~= 0 then
    unlink(temporary_lsf)
    conversion_error("compile LSX", result)
  end
  if read_lsof_signature(temporary_lsf) ~= "LSOF" then
    unlink(temporary_lsf)
    error("bg3-lsf: converter output does not have an LSOF signature", 0)
  end

  assert_unchanged(state)
  local changed, chmod_error = vim.uv.fs_chmod(temporary_lsf, state.fingerprint.mode)
  if not changed then
    unlink(temporary_lsf)
    error("bg3-lsf: could not preserve file permissions: " .. chmod_error, 0)
  end
  local renamed, rename_error = vim.uv.fs_rename(temporary_lsf, state.path)
  if not renamed then
    unlink(temporary_lsf)
    error("bg3-lsf: could not replace source LSF: " .. rename_error, 0)
  end

  state.fingerprint = fingerprint(state.path)
  vim.bo[buffer].modified = false
  vim.api.nvim_exec_autocmds("BufWritePost", { buffer = buffer, modeline = false })
end

function M.setup()
  local group = vim.api.nvim_create_augroup("bg3_lsf", { clear = true })
  vim.api.nvim_create_autocmd("BufReadCmd", {
    group = group,
    pattern = "*.lsf",
    callback = function(event) read(event.buf, vim.fs.abspath(event.file)) end,
  })
end

return M
