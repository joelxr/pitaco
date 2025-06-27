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

local function parse_response(response, buf_nr, callback_table)
	local diagnostics = {}
	local lines = vim.split(response.choices[1].message.content, "\n")
	local suggestions = {}

	for _, line in ipairs(lines) do
		if (string.sub(line, 1, 5) == "line=") or string.sub(line, 1, 6) == "lines=" then
			table.insert(suggestions, line)
		elseif #suggestions > 0 then
			suggestions[#suggestions] = suggestions[#suggestions] .. "\n" .. line
		end
	end

	if #suggestions ~= 0 then
		complete_progress(
			callback_table.handle,
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

	vim.diagnostic.set(pitaco_namespace, buf_nr, diagnostics, {})
end

local function prepare_code_snippet(buf_nr, starting_line_number, ending_line_number)
	local lines = vim.api.nvim_buf_get_lines(buf_nr, starting_line_number - 1, ending_line_number, false)
	local max_digits = string.len(tostring(#lines + starting_line_number))

	for i, line in ipairs(lines) do
		lines[i] = string.format("%0" .. max_digits .. "d", i - 1 + starting_line_number) .. " " .. line
	end

	local text = table.concat(lines, "\n")
	return text
end

local function pitaco_send_from_request_queue(callback_table)
	if #callback_table.requests == 0 then
		return nil
	end

	local buf_name = vim.fn.fnamemodify(vim.fn.bufname(callback_table.buf_nr), ":t")
	local handle

	if callback_table.request_index == 0 then
		if callback_table.starting_request_count == 1 then
			handle = show_progress("Pitaco", "Sending " .. buf_name .. " (" .. callback_table.line_count .. " lines)")
		else
			handle = show_progress(
				"Pitaco",
				"Sending " .. buf_name .. " (split into " .. callback_table.starting_request_count .. " requests)"
			)
		end
		callback_table.handle = handle
	end

	local request_json = table.remove(callback_table.requests, 1)
	callback_table.request_index = callback_table.request_index + 1

	update_progress(
		callback_table.handle,
		"Processing request " .. callback_table.request_index .. " of " .. callback_table.starting_request_count,
		callback_table.request_index,
		callback_table.starting_request_count
	)

	local response_table = openai.request(request_json)

	if response_table then
		parse_response(response_table, callback_table.buf_nr, callback_table)
	end

	if callback_table.request_index < callback_table.starting_request_count + 1 then
		pitaco_send_from_request_queue(callback_table)
	end
end

vim.api.nvim_create_user_command("Pitaco", function()
	local split_threshold = config.get_split_threshold()
	local buf_nr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(buf_nr, 0, -1, false)
	local num_requests = math.ceil(#lines / split_threshold)

	local request_table = {
		model = openai.get_model(),
		messages = fewshot.messages,
	}

	local requests = {}

	for i = 1, num_requests do
		local starting_line_number = (i - 1) * split_threshold + 1
		local text = prepare_code_snippet(buf_nr, starting_line_number, starting_line_number + split_threshold - 1)
		local language = config.get_language()
		local additional_instruction = config.get_additional_instruction()

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
		requests[i] = request_json
	end

	pitaco_send_from_request_queue({
		requests = requests,
		starting_request_count = num_requests,
		request_index = 0,
		buf_nr = buf_nr,
		line_count = #lines,
	})
end, {})

vim.api.nvim_create_user_command("PitacoClear", function()
	local buf_nr = vim.api.nvim_get_current_buf()
	vim.diagnostic.reset(pitaco_namespace, buf_nr)
end, {})

vim.api.nvim_create_user_command("PitacoClearLine", function()
	local buf_nr = vim.api.nvim_get_current_buf()
	local line_num = vim.api.nvim_win_get_cursor(0)[1]
	vim.diagnostic.set(pitaco_namespace, buf_nr, {}, { lnum = line_num - 1 })
end, {})
