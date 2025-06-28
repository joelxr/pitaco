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
		local response = provider.request(request_json)

		if response then
			provider.parse_response(response)
		end

		if request_index < starting_request_count + 1 then
			M.make_requests(namespace, provider, requests, starting_request_count, request_index, line_count)
		end
	end, 100)
end

return M
