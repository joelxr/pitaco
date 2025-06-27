if vim.g.loaded_pitaco then
	return
end

vim.g.loaded_pitaco = true

local pitaco = require("pitaco")

pitaco.setup()

local pitaco_namespace = vim.api.nvim_create_namespace("pitaco")
local fewshot = require("pitaco.fewshot")
local progress = require("pitaco.progress")
local openai = require("pitaco.openai")
local config = require("pitaco.config")
local utils = require("pitaco.utils")
local requests = require("pitaco.requests")

local function pitaco_command()
	local split_threshold = config.get_split_threshold()
	local language = config.get_language()
	local additional_instruction = config.get_additional_instruction()
	local buffer_number = vim.api.nvim_get_current_buf()

	local request_table = {
		model = openai.get_model(),
		messages = fewshot.messages,
	}

	local all_requests, num_requests, line_count =
		requests.prepare_requests(buffer_number, split_threshold, language, additional_instruction, request_table)

	requests.make_requests({
		requests = all_requests,
		starting_request_count = num_requests,
		request_index = 0,
		buf_nr = buffer_number,
		line_count = line_count,
	})
end

local function pitaco_clear_command()
	local buf_nr = vim.api.nvim_get_current_buf()
	vim.diagnostic.reset(pitaco_namespace, buf_nr)
end

local function pitaco_clear_line_command()
	local buf_nr = vim.api.nvim_get_current_buf()
	local line_num = vim.api.nvim_win_get_cursor(0)[1]
	vim.diagnostic.set(pitaco_namespace, buf_nr, {}, { lnum = line_num - 1 })
end

vim.api.nvim_create_user_command("Pitaco", pitaco_command, {})
vim.api.nvim_create_user_command("PitacoClear", pitaco_clear_command, {})
vim.api.nvim_create_user_command("PitacoClearLine", pitaco_clear_line_command, {})
