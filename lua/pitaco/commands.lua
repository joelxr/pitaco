local M = {}

local pitaco_namespace = vim.api.nvim_create_namespace("pitaco")
local fewshot = require("pitaco.fewshot")
local openai = require("pitaco.openai")
local config = require("pitaco.config")
local requests = require("pitaco.requests")

function M.review()
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
		namespace = pitaco_namespace,
		requests = all_requests,
		starting_request_count = num_requests,
		request_index = 0,
		buf_nr = buffer_number,
		line_count = line_count,
	})
end

function M.clear()
	local buf_nr = vim.api.nvim_get_current_buf()
	vim.diagnostic.reset(pitaco_namespace, buf_nr)
end

function M.clear_line()
	local buf_nr = vim.api.nvim_get_current_buf()
	local line_num = vim.api.nvim_win_get_cursor(0)[1]
	vim.diagnostic.set(pitaco_namespace, buf_nr, {}, { lnum = line_num - 1 })
end

return M
