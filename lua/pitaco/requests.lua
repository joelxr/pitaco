local progress = require("pitaco.progress")
local config = require("pitaco.config")
local utils = require("pitaco.utils")
local openai = require("pitaco.providers.openai")
local fewshot = require("pitaco.fewshot")

local M = {}

function M.parse_response(response, params)
	local lines = vim.split(response.choices[1].message.content, "\n")
	local diagnostics = {}
	local suggestions = {}

	for _, line in ipairs(lines) do
		if (string.sub(line, 1, 5) == "line=") or string.sub(line, 1, 6) == "lines=" then
			table.insert(suggestions, line)
		elseif #suggestions > 0 then
			suggestions[#suggestions] = suggestions[#suggestions] .. "\n" .. line
		end
	end

	if #suggestions ~= 0 then
		progress.complete_progress(
			params.handle,
			#suggestions .. " suggestion(s) using " .. response.usage.total_tokens .. " tokens"
		)
	end

	for _, suggestion in ipairs(suggestions) do
		local line_string = string.sub(suggestion, 6, string.find(suggestion, ":") - 1)
		if string.find(line_string, "-") ~= nil then
			line_string = string.sub(line_string, 1, string.find(line_string, "-") - 1)
		end
		local line_num = tonumber(line_string)

		if line_num == nil then
			line_num = 1
		end
		local message = string.sub(suggestion, string.find(suggestion, ":") + 1, string.len(suggestion))
		if string.sub(message, 1, 1) == " " then
			message = string.sub(message, 2, string.len(message))
		end
		table.insert(diagnostics, {
			lnum = line_num - 1,
			col = 0,
			message = message,
			severity = vim.diagnostic.severity.INFO,
			source = "pitaco",
		})
	end

	vim.diagnostic.set(params.namespace, utils.get_buffer_number(), diagnostics, {})
end

function M.prepare_requests()
  local model = config.get_model()
  local buffer_number = utils.get_buffer_number()
  local split_threshold = config.get_split_threshold()
  local language = config.get_language()
  local additional_instruction = config.get_additional_instruction()
	local lines = vim.api.nvim_buf_get_lines(buffer_number, 0, -1, false)
	local num_requests = math.ceil(#lines / split_threshold)
	local all_requests = {}
  local request_table = {
    model = model,
    messages = fewshot.messages,
  }

	for i = 1, num_requests do
		local starting_line_number = (i - 1) * split_threshold + 1
		local text =
			utils.prepare_code_snippet(buffer_number, starting_line_number, starting_line_number + split_threshold - 1)

		if additional_instruction ~= "" then
			text = text .. "\n" .. additional_instruction
		end

		if language ~= "" and language ~= "english" then
			text = text .. "\nRespond only in " .. language .. ", but keep the 'line=<num>:' part in english"
		end

		local temp_request_table = vim.deepcopy(request_table)

		table.insert(temp_request_table.messages, {
			role = "user",
			content = text,
		})

		local request_json = vim.json.encode(temp_request_table)
		all_requests[i] = request_json
	end

	return all_requests, num_requests, #lines
end

function M.make_requests(params)
	if #params.requests == 0 then
		return nil
	end

	progress.show_buffer_progress(params)

	local request_json = table.remove(params.requests, 1)
	params.request_index = params.request_index + 1

	progress.update_progress(
		params.handle,
		"Processing request " .. params.request_index .. " of " .. params.starting_request_count,
		params.request_index,
		params.starting_request_count
	)

	vim.defer_fn(function()
		local response = openai.request(request_json)

		if response then
			M.parse_response(response, params)
		end

		if params.request_index < params.starting_request_count + 1 then
			M.make_requests(params)
		end
	end, 100)
end

return M
