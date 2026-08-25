local M = {}

local namespace = vim.api.nvim_create_namespace("bg3_localization_markup")
local highlight_priority = 150

local function highlight(buffer, row, start_column, end_column, group)
  vim.api.nvim_buf_set_extmark(buffer, namespace, row, start_column, {
    end_row = row,
    end_col = end_column,
    hl_group = group,
    priority = highlight_priority,
  })
end

local function next_open_delimiter(line, offset)
  local encoded = line:find("&lt;", offset, true)
  local literal = line:find("<", offset, true)
  if encoded and (not literal or encoded < literal) then return encoded, 4 end
  if literal then return literal, 1 end
end

local function next_close_delimiter(line, offset)
  local encoded = line:find("&gt;", offset, true)
  local literal = line:find(">", offset, true)
  if encoded and (not literal or encoded < literal) then return encoded, 4 end
  if literal then return literal, 1 end
end

-- Highlights every quoted attribute inside one open tag region. Any
-- attribute name receives the attribute group so `Type` behaves exactly like
-- `Tooltip`.
local function highlight_attributes(buffer, row, line, start_column, end_column)
  local offset = start_column
  while offset <= end_column do
    local _, value_end, name_start, name, quote_start, quote = line:find("()([%a_][%w%-%.]*)%s*=%s*()([\"'])", offset)
    if not name_start or quote_start > end_column then return end
    if not value_end or value_end > end_column then return end

    highlight(buffer, row, name_start - 1, name_start - 1 + #name, "@tag.attribute")
    highlight(buffer, row, quote_start - 1, value_end, "@string.special")
    offset = value_end + 1
  end
end
-- Highlights one inline tag plus its delimiters and returns the offset after
-- the closing delimiter. A self-closing slash stays part of the name span.
-- Returns nil when the tag is unterminated so the caller stops this line.
local function highlight_inline_tag(buffer, row, line, open_start, open_length, name)
  local name_start = open_start + open_length
  local closing = line:sub(name_start, name_start) == "/"
  if closing then name_start = name_start + 1 end
  local name_end = name_start + #name - 1
  local following = line:sub(name_end + 1, name_end + 1)
  if not following:match("[%s>/;&]") then return nil end

  local close_start, close_length = next_close_delimiter(line, name_end + 1)
  if not close_start then return nil end

  highlight(buffer, row, open_start - 1, name_start - 1, "@punctuation.bracket")
  -- A self-closing slash (and its encoded terminator) joins the name span.
  local trailing = line:sub(name_end + 1, close_start - 1)
  local exclusive_end = trailing:match("^[%s/;]*$") and close_start - 1 or name_end
  highlight(buffer, row, name_start - 1, exclusive_end, "@tag")
  highlight(buffer, row, close_start - 1, close_start + close_length - 1, "@punctuation.bracket")
  if not closing then highlight_attributes(buffer, row, line, name_end + 1, close_start - 1) end
  return close_start + close_length
end

local function highlight_line(buffer, row, line)
  local offset = 1
  while offset <= #line do
    local open_start, open_length = next_open_delimiter(line, offset)
    if not open_start then return end

    local name_start = open_start + open_length
    local name = line:match("^[%a_]+", name_start)
    local next_offset
    if name == "LSTag" and line:sub(name_start + #name):match("^[%s>/;&]") then
      local name_end = name_start + #name - 1
      local close_start, close_length = next_close_delimiter(line, name_end + 1)
      if not close_start then return end

      highlight(buffer, row, open_start - 1, name_start - 1, "@punctuation.bracket")
      highlight(buffer, row, name_start - 1, name_end, "@tag")
      highlight(buffer, row, close_start - 1, close_start + close_length - 1, "@punctuation.bracket")
      if line:sub(name_start, name_start) ~= "/" then
        highlight_attributes(buffer, row, line, name_end + 1, close_start - 1)
      end
      next_offset = close_start + close_length
    elseif name == "br" then
      next_offset = highlight_inline_tag(buffer, row, line, open_start, open_length, name)
      if not next_offset then return end
    else
      next_offset = open_start + open_length
    end
    offset = math.max(next_offset, offset + 1)
  end
end

local function highlight_range(buffer, first_line, last_line)
  vim.api.nvim_buf_clear_namespace(buffer, namespace, first_line, last_line)
  for index, line in ipairs(vim.api.nvim_buf_get_lines(buffer, first_line, last_line, false)) do
    highlight_line(buffer, first_line + index - 1, line)
  end
end

function M.setup(buffer)
  if vim.b[buffer].bg3_localization_markup then return end
  vim.b[buffer].bg3_localization_markup = true
  highlight_range(buffer, 0, -1)
  vim.api.nvim_buf_attach(buffer, false, {
    on_lines = function(_, changed_buffer, _, first_line, _, new_last_line)
      highlight_range(changed_buffer, first_line, new_last_line)
    end,
  })
end

return M
