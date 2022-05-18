local render = require("overseer.render")
local registry = require("overseer.registry")
local util = require("overseer.util")
local M = {}

local function create_overseer_buffer()
  local bufnr = vim.api.nvim_create_buf(false, true)

  -- Set buffer options
  vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(bufnr, "buflisted", false)
  vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  return bufnr
end

local function create_overseer_window()
  local bufnr = create_overseer_buffer()

  local my_winid = vim.api.nvim_get_current_win()
  local direction = "left"
  local modifier = direction == "left" and "topleft" or "botright"
  local winids = util.get_fixed_wins(bufnr)
  local split_target
  if direction == "left" then
    split_target = winids[1]
  else
    split_target = winids[#winids]
  end
  if my_winid ~= split_target then
    util.go_win_no_au(split_target)
  end
  vim.cmd(string.format("noau vertical %s split", modifier))

  util.go_buf_no_au(bufnr)
  vim.api.nvim_win_set_option(0, "listchars", "tab:> ")
  vim.api.nvim_win_set_option(0, "winfixwidth", true)
  vim.api.nvim_win_set_option(0, "number", false)
  vim.api.nvim_win_set_option(0, "signcolumn", "no")
  vim.api.nvim_win_set_option(0, "foldcolumn", "0")
  vim.api.nvim_win_set_option(0, "relativenumber", false)
  vim.api.nvim_win_set_option(0, "wrap", false)
  vim.api.nvim_win_set_option(0, "spell", false)
  vim.api.nvim_win_set_width(0, 80)
  -- Set the filetype only after we enter the buffer so that FileType autocmds
  -- behave properly
  vim.api.nvim_buf_set_option(bufnr, "filetype", "overseer")

  local winid = vim.api.nvim_get_current_win()
  util.go_win_no_au(my_winid)
  render.update_buffer(bufnr)
  registry.add_update_callback(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      render.update_buffer(bufnr)
      return true
    else
      return false
    end
  end)
  return winid
end

M.get_win_id = function()
  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local bufnr = vim.api.nvim_win_get_buf(winid)
    if vim.api.nvim_buf_get_option(bufnr, "filetype") == "overseer" then
      return winid
    end
  end
end

M.is_open = function()
  return M.get_win_id() ~= nil
end

M.open = function()
  if M.is_open() then
    return
  end
  local winid = create_overseer_window()
  vim.api.nvim_set_current_win(winid)
end

M.toggle = function()
  if M.is_open() then
    M.close()
  else
    M.open()
  end
end

M.close = function()
  local winid = M.get_win_id()
  if winid then
    vim.api.nvim_win_close(winid, false)
  end
end

return M
