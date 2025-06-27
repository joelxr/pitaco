-- This is a plugin for the Neovim text editor
-- Author: Joel
-- License: MIT
-- Source: https://github.com/joelxr/pitaco

if vim.g.loaded_pitaco then
	return
end

vim.g.loaded_pitaco = true

local pitaco = require("pitaco")

pitaco.setup()

local commands = require("pitaco.commands")

vim.api.nvim_create_user_command("Pitaco", commands.review, {})
vim.api.nvim_create_user_command("PitacoClear", commands.clear, {})
vim.api.nvim_create_user_command("PitacoClearLine", commands.clear_line, {})
