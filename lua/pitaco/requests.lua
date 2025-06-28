local progress = require("pitaco.progress")

local M = {}

function M.make_requests(namespace, provider, requests, starting_request_count, request_index, line_count)
	if #requests == 0 then
		return nil
	end

	local params = {
		namespace = namespace,
		requests = requests,
		starting_request_count = starting_request_count,
		request_index = request_index,
		line_count = line_count,
	}

	progress.show_buffer_progress(params)

	local request_json = table.remove(requests, 1)
	request_index = request_index + 1

	progress.update_progress(
		params.handle,
		"Processing request " .. request_index .. " of " .. starting_request_count,
		request_index,
		starting_request_count
	)

	vim.defer_fn(function()
		local ok, response = pcall(provider.request, request_json)

		if not ok then
			progress.update_progress(
				params.handle,
				tostring(response),
				request_index,
				starting_request_count
			)
			progress.complete_progress(params.handle, "Error making request")
			return
		end

		if response then
			local parse_ok, diagnostics = pcall(provider.parse_response, response)

			if not parse_ok then
				progress.update_progress(
					params.handle,
					"Failed to parse response",
					request_index,
					starting_request_count
				)
				progress.complete_progress(params.handle, "Error parsing response")
				return
			end
			vim.diagnostic.set(namespace, params.buffer_number, diagnostics, {})
		end

		if request_index < starting_request_count + 1 then
			M.make_requests(namespace, provider, requests, starting_request_count, request_index, line_count)
		else
			progress.complete_progress(params.handle, "Done!")
		end
	end, 100)
end

return M
