local M = {}
local Job = require('plenary.job')

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

	Job:new({
		command = 'curl',
		args = {
			'-s',
			'https://api.openai.com/v1/chat/completions',
			'-H', 'Content-Type: application/json',
			'-H', 'Authorization: Bearer ' .. api_key,
			'--data-binary', dataJSON
		},
		on_exit = function(j, return_val)
			local response = table.concat(j:result(), "\n")
			local success, responseTable = pcall(vim.json.decode, response)

			if not success or not responseTable then
				print("Bad or no response: " .. (response or "nil"))
				return
			end

			if responseTable.error then
				print("OpenAI Error: " .. responseTable.error.message)
				return
			end

			callback(responseTable, callbackTable)
		end,
	}):start()
end

return M
