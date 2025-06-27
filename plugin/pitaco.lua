if vim.g.loaded_pitaco then
	return
end

vim.g.loaded_pitaco = true

local pitaco = require("pitaco")

pitaco.setup()

local pitacoNamespace = vim.api.nvim_create_namespace("pitaco")
local fewshot = require("pitaco.fewshot")
local progress = require("fidget.progress")
local openai = require("pitaco.openai")
local config = require("pitaco.config")

local function show_progress(title, message)
	local handle = progress.handle.create({
		title = title,
		message = message,
		percentage = 0,
		lsp_client = { name = "pitaco" },
	})
	return handle
end

local function update_progress(handle, message, currentIndex, totalRequests)
	local percentage = math.floor((currentIndex / totalRequests) * 100)

	handle:report({
		message = message,
		percentage = percentage,
	})
end

local function complete_progress(handle, message)
	handle:finish()
	handle:report({
		message = message,
		percentage = 100,
	})
end

local function parse_response(response, bufnr, callbackTable)
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
			callbackTable.handle,
			#suggestions .. " suggestion(s) using " .. response.usage.total_tokens .. " tokens"
		)
	end

	for _, suggestion in ipairs(suggestions) do
		local lineString = string.sub(suggestion, 6, string.find(suggestion, ":") - 1)
		if string.find(lineString, "-") ~= nil then
			lineString = string.sub(lineString, 1, string.find(lineString, "-") - 1)
		end
		local lineNum = tonumber(lineString)

		if lineNum == nil then
			lineNum = 1
		end
		local message = string.sub(suggestion, string.find(suggestion, ":") + 1, string.len(suggestion))
		if string.sub(message, 1, 1) == " " then
			message = string.sub(message, 2, string.len(message))
		end
		table.insert(diagnostics, {
			lnum = lineNum - 1,
			col = 0,
			message = message,
			severity = vim.diagnostic.severity.INFO,
			source = "pitaco",
		})
	end

	vim.diagnostic.set(pitacoNamespace, bufnr, diagnostics, {})
end

local function prepare_code_snippet(bufnr, startingLineNumber, endingLineNumber)
	local lines = vim.api.nvim_buf_get_lines(bufnr, startingLineNumber - 1, endingLineNumber, false)
	local maxDigits = string.len(tostring(#lines + startingLineNumber))

	for i, line in ipairs(lines) do
		lines[i] = string.format("%0" .. maxDigits .. "d", i - 1 + startingLineNumber) .. " " .. line
	end

	local text = table.concat(lines, "\n")
	return text
end

local pitaco_callback
local function pitaco_send_from_request_queue(callbackTable)
	if #callbackTable.requests == 0 then
		return nil
	end

	local bufname = vim.fn.fnamemodify(vim.fn.bufname(callbackTable.bufnr), ":t")
	local handle

	if callbackTable.requestIndex == 0 then
		if callbackTable.startingRequestCount == 1 then
			handle = show_progress("Pitaco", "Sending " .. bufname .. " (" .. callbackTable.lineCount .. " lines)")
		else
			handle = show_progress(
				"Pitaco",
				"Sending " .. bufname .. " (split into " .. callbackTable.startingRequestCount .. " requests)"
			)
		end
		callbackTable.handle = handle
	end

	local requestJSON = table.remove(callbackTable.requests, 1)
	callbackTable.requestIndex = callbackTable.requestIndex + 1

	update_progress(
		callbackTable.handle,
		"Processing request " .. callbackTable.requestIndex .. " of " .. callbackTable.startingRequestCount,
		callbackTable.requestIndex,
		callbackTable.startingRequestCount
	)

	local response = openai.request(requestJSON)
	pitaco_callback(response, callbackTable)
end

function pitaco_callback(responseTable, callbackTable)
	if responseTable ~= nil then
		if callbackTable.startingRequestCount == 1 then
			parse_response(responseTable, callbackTable.bufnr, callbackTable)
		else
			parse_response(responseTable, callbackTable.bufnr, callbackTable)
		end
	end

	if callbackTable.requestIndex < callbackTable.startingRequestCount + 1 then
		pitaco_send_from_request_queue(callbackTable)
	end
end

vim.api.nvim_create_user_command("Pitaco", function()
	local splitThreshold = config.get_split_threshold()
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local numRequests = math.ceil(#lines / splitThreshold)

	local requestTable = {
		model = openai.get_model(),
		messages = fewshot.messages,
	}

	local requests = {}

	for i = 1, numRequests do
		local startingLineNumber = (i - 1) * splitThreshold + 1
		local text = prepare_code_snippet(bufnr, startingLineNumber, startingLineNumber + splitThreshold - 1)
		local language = config.get_language()
		local additional_instruction = config.get_additional_instruction()

		if additional_instruction ~= "" then
			text = text .. "\n" .. additional_instruction
		end

		if language ~= "" and language ~= "english" then
			text = text .. "\nRespond only in " .. language .. ", but keep the 'line=<num>:' part in english"
		end

		local tempRequestTable = vim.deepcopy(requestTable)

		table.insert(tempRequestTable.messages, {
			role = "user",
			content = text,
		})

		local requestJSON = vim.json.encode(tempRequestTable)
		requests[i] = requestJSON
	end

	pitaco_send_from_request_queue({
		requests = requests,
		startingRequestCount = numRequests,
		requestIndex = 0,
		bufnr = bufnr,
		lineCount = #lines,
	})
end, {})

vim.api.nvim_create_user_command("PitacoClear", function()
	local bufnr = vim.api.nvim_get_current_buf()
	vim.diagnostic.reset(pitacoNamespace, bufnr)
end, {})

vim.api.nvim_create_user_command("PitacoClearLine", function()
	local bufnr = vim.api.nvim_get_current_buf()
	local lineNum = vim.api.nvim_win_get_cursor(0)[1]
	vim.diagnostic.set(pitacoNamespace, bufnr, {}, { lnum = lineNum - 1 })
end, {})
