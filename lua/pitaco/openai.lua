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

function M.request(json_data)
	local api_key = get_api_key()

	if api_key == nil then
		return nil
	end

	local ok, response = pcall(curl.post, "https://api.openai.com/v1/chat/completions", {
		headers = {
			["Content-Type"] = "application/json",
			["Authorization"] = "Bearer " .. api_key,
		},
		body = json_data,
		timeout = 30000, -- 30s
	})

	if not ok then
		print("Request failed:", response)
		return
	end

	if response.status >= 400 then
		print("HTTP error:", response.status, response.body)
		return
	end

	local body = vim.fn.json_decode(response.body)
	return body
end

return M
