local M = {}
local curl = require("plenary.curl")

local function get_api_key()
	local key = os.getenv("OPENAI_API_KEY")

	if key ~= nil then
		return key
	end

	local message = "No API key found. Please set the $OPENAI_API_KEY environment variable."
	vim.fn.confirm(message, "&OK", 1, "Warning")
	return nil
end

function M.gpt_request(dataJSON)
	local api_key = get_api_key()

	if api_key == nil then
		return nil
	end

	return curl.post("https://api.openai.com/v1/chat/completions", {
		headers = {
			["Content-Type"] = "application/json",
			["Authorization"] = "Bearer " .. api_key,
		},
		body = dataJSON,
		callback = function(response)
			local responseBody = response.body
			local success, responseTable = pcall(vim.json.decode, responseBody)
			if not success or not responseTable then
				print("Bad or no response: " .. (responseBody or "nil"))
				return
			end

			if responseTable.error then
				print("OpenAI Error: " .. responseTable.error.message)
				return
			end

			-- Handle the response directly here
			-- Example: print the response or process it as needed
			print(vim.inspect(responseTable))
		end,
	})
end

return M
