if vim.g.loaded_pitaco then
	return
end

vim.g.loaded_pitaco = true

require("pitaco").setup()

require("fidget").setup({
    text = {
        spinner = "dots", -- animation for ongoing tasks
        done = "✔", -- symbol for completed tasks
    },
    align = {
        bottom = true, -- align fidgets along the bottom
    },
    window = {
        relative = "editor", -- position relative to the editor
        blend = 0, -- no transparency
        zindex = nil, -- use default zindex
        border = "none", -- no border
    },
    fmt = {
        task = function(task_name, message, percentage)
            return string.format("pitaco: %s [%s%%]", message, percentage)
        end,
    },
    sources = {
        ["*"] = {
            ignore = false, -- do not ignore any sources
        },
    },
    debug = {
        logging = false, -- disable logging
    },
})

local fewshot = require("pitaco.fewshot")
local pitacoNamespace = vim.api.nvim_create_namespace("pitaco")
local progress = require("fidget.progress")

local function show_progress(title, message)
	local handle = progress.handle.create({
		title = title,
		message = message,
		percentage = 0,
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

local function get_api_key()
	local key = os.getenv("OPENAI_API_KEY")

	if key ~= nil then
		return key
	end

	local message = "No API key found. Please set the $OPENAI_API_KEY environment variable."
	vim.fn.confirm(message, "&OK", 1, "Warning")
	return nil
end

local function get_model()
	local model = vim.g.pitaco_openai_model_id

	if model ~= nil then
		return model
	end

	if vim.g.pitaco_model_id_complained == nil then
		local message = "No model specified. Please set openai_model_id in the setup table. Using default value for now"
		vim.fn.confirm(message, "&OK", 1, "Warning")
		vim.g.pitaco_model_id_complained = 1
	end

	return "gpt-4.1-mini"
end

local function get_language()
	return vim.g.pitaco_language
end

local function get_additional_instruction()
	return vim.g.pitaco_additional_instruction or ""
end

local function get_split_threshold()
	return vim.g.pitaco_split_threshold
end
local function gpt_request(dataJSON, callback, callbackTable)
	local api_key = get_api_key()
	if api_key == nil then
		return nil
	end

	if vim.fn.executable("curl") == 0 then
		vim.fn.confirm("curl installation not found. Please install curl to use pitaco", "&OK", 1, "Warning")
		return nil
	end

	local curlRequest
	local tempFilePath = vim.fn.tempname()
	local tempFile = io.open(tempFilePath, "w")

	if tempFile == nil then
		print("Error creating temp file")
		return nil
	end

	tempFile:write(dataJSON)
	tempFile:close()

	local tempFilePathEscaped = vim.fn.fnameescape(tempFilePath)
	local isWindows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1

	if isWindows ~= true then
		-- Linux
		curlRequest = string.format(
			'curl -s https://api.openai.com/v1/chat/completions -H "Content-Type: application/json" -H "Authorization: Bearer '
				.. api_key
				.. '" --data-binary "@'
				.. tempFilePathEscaped
				.. '"; rm '
				.. tempFilePathEscaped
				.. " > /dev/null 2>&1"
		)
	else
		-- Windows
		curlRequest = string.format(
			'curl -s https://api.openai.com/v1/chat/completions -H "Content-Type: application/json" -H "Authorization: Bearer '
				.. api_key
				.. '" --data-binary "@'
				.. tempFilePathEscaped
				.. '" & del '
				.. tempFilePathEscaped
				.. " > nul 2>&1"
		)
	end

	vim.fn.jobstart(curlRequest, {
		stdout_buffered = true,
		on_stdout = function(_, data, _)
			local response = table.concat(data, "\n")
			local success, responseTable = pcall(vim.json.decode, response)

			if success == false or responseTable == nil then
				if response == nil then
					response = "nil"
				end
				print("Bad or no response: " .. response)
				return nil
			end

			if responseTable.error ~= nil then
				print("OpenAI Error: " .. responseTable.error.message)
				return nil
			end

			callback(responseTable, callbackTable)
		end,
		on_stderr = function(_, data, _)
			return data
		end,
		on_exit = function(_, data, _)
			return data
		end,
	})
end

local function parse_response(response, partNumberString, bufnr, callbackTable)
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
	gpt_request(requestJSON, pitaco_callback, callbackTable)
end

function pitaco_callback(responseTable, callbackTable)
	if responseTable ~= nil then
		if callbackTable.startingRequestCount == 1 then
			parse_response(responseTable, "", callbackTable.bufnr, callbackTable)
		else
			parse_response(
				responseTable,
				" (request " .. callbackTable.requestIndex .. " of " .. callbackTable.startingRequestCount .. ")",
				callbackTable.bufnr,
				callbackTable
			)
		end
	end

	if callbackTable.requestIndex < callbackTable.startingRequestCount + 1 then
		pitaco_send_from_request_queue(callbackTable)
	end
end

vim.api.nvim_create_user_command("Pitaco", function()
	local splitThreshold = get_split_threshold()
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local numRequests = math.ceil(#lines / splitThreshold)
	local model = get_model()

	local requestTable = {
		model = model,
		messages = fewshot.messages,
	}

	local requests = {}

	for i = 1, numRequests do
		local startingLineNumber = (i - 1) * splitThreshold + 1
		local text = prepare_code_snippet(bufnr, startingLineNumber, startingLineNumber + splitThreshold - 1)

		if get_additional_instruction() ~= "" then
			text = text .. "\n" .. get_additional_instruction()
		end

		if get_language() ~= "" and get_language() ~= "english" then
			text = text .. "\nRespond only in " .. get_language() .. ", but keep the 'line=<num>:' part in english"
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
