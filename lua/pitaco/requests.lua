local progress = require("pitaco.progress")
local utils = require("pitaco.utils")

local M = {}

function M.make_requests(namespace, provider, requests, starting_request_count, request_index, line_count)
	if #requests == 0 then
		return nil
	end

	local request_json = table.remove(requests, 1)
	request_index = request_index + 1

	progress.update(
		"Processing request " .. request_index .. " of " .. starting_request_count,
		request_index,
		starting_request_count
	)

	provider.request(request_json, function(response, error_message)
		if error_message ~= nil then
			print(error_message)
			progress.stop()
			return
		end

		if response == nil then
			progress.stop()
			return
		end

		if response then
			local parse_ok, diagnostics = pcall(provider.parse_response, response)

			if not parse_ok then
				print("Failed to parse response")
				progress.stop()
				return
			end

			vim.schedule(function()
				vim.diagnostic.set(namespace, utils.get_buffer_number(), diagnostics)
			end)
		end

		if request_index < starting_request_count + 1 then
			M.make_requests(namespace, provider, requests, starting_request_count, request_index, line_count)
		else
			progress.stop()
		end
	end)
end

return M
