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

local function make_requests(params)
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

    local response = openai.request(request_json)

    if response then
        requests.parse_response(response, params.buf_nr, params)
    end

    if params.request_index < params.starting_request_count + 1 then
        make_requests(params)
    end
end

local function prepare_requests(buf_nr, split_threshold, language, additional_instruction, request_table)
	local lines = vim.api.nvim_buf_get_lines(buf_nr, 0, -1, false)
	local num_requests = math.ceil(#lines / split_threshold)
	local requests = {}

	for i = 1, num_requests do
		local starting_line_number = (i - 1) * split_threshold + 1
		local text = utils.prepare_code_snippet(buf_nr, starting_line_number, starting_line_number + split_threshold - 1)

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

	return requests, num_requests, #lines
end

local function pitaco_command()
	local split_threshold = config.get_split_threshold()
	local language = config.get_language()
	local additional_instruction = config.get_additional_instruction()
	local buffer_number = vim.api.nvim_get_current_buf()

	local request_table = {
		model = openai.get_model(),
		messages = fewshot.messages,
	}

	local requests, num_requests, line_count = prepare_requests(buffer_number, split_threshold, language, additional_instruction, request_table)

	make_requests({
		requests = requests,
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
