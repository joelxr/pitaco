local M = {}

local provider_factory = require("pitaco.providers.factory")
local config = require("pitaco.config")
local utils = require("pitaco.utils")
local requests = require("pitaco.requests")
local fewshot = require("pitaco.fewshot")
local namespace = vim.api.nvim_create_namespace("pitaco")

function M.review()
	local provider = provider_factory.create_provider(config.get_provider())
	local all_requests, num_requests, line_count = provider.prepare_requests(fewshot.messages)
  requests.make_requests(namespace, provider, all_requests, num_requests, 0, line_count)
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
