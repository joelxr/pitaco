local M = {}

local namespace = vim.api.nvim_create_namespace("pitaco")
local fewshot = require("pitaco.fewshot")
local openai = require("pitaco.providers.openai")
local config = require("pitaco.config")
local utils = require("pitaco.utils")
local requests = require("pitaco.requests")

function M.review()
	local split_threshold = config.get_split_threshold()
	local language = config.get_language()
	local additional_instruction = config.get_additional_instruction()
	local buffer_number = utils.get_buffer_number()
  local model = config.get_model()

  local request_table = {
		model = model,
		messages = fewshot.messages,
	}

	local all_requests, num_requests, line_count =
		requests.prepare_requests(buffer_number, split_threshold, language, additional_instruction, request_table)

	requests.make_requests({
		namespace = namespace,
		requests = all_requests,
		starting_request_count = num_requests,
		request_index = 0,
		buf_nr = buffer_number,
		line_count = line_count,
	})
end

function M.clear()
	local buffer_number = utils.get_buffer_number()
	vim.diagnostic.reset(namespace, buffer_number)
end

function M.clear_line()
	local buffer_number = utils.get_buffer_number()
	local line_num = vim.api.nvim_win_get_cursor(0)[1]
	vim.diagnostic.set(namespace, buffer_number, {}, { lnum = line_num - 1 })
end

return M
