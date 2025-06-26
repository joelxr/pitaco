local M = {}

local function get_api_key()
	local key = os.getenv("OPENAI_API_KEY")

	if key ~= nil then
		return key
	end

	local message = "No API key found. Please set the $OPENAI_API_KEY environment variable."
	vim.fn.confirm(message, "&OK", 1, "Warning")
	return nil
end

function M.gpt_request(dataJSON, callback, callbackTable)
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

return M
