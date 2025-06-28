local M = {}
local progress = require("fidget.progress")
local utils = require("pitaco.utils")

function M.show_progress(title, message)
	local handle = progress.handle.create({
		title = title,
		message = message,
		percentage = 0,
		lsp_client = { name = "pitaco" },
	})
	return handle
end

function M.update_progress(handle, message, current_index, total_requests)
	local percentage = math.floor((current_index / total_requests) * 100)

	handle:report({
		message = message,
		percentage = percentage,
	})

	vim.defer_fn(function()
		handle:report({
			message = message,
			percentage = percentage,
		})
	end, 100)
end

function M.complete_progress(handle, message)
	handle:finish()
	handle:report({
		message = message,
		percentage = 100,
	})
end

function M.show_buffer_progress(params)
  local buffer_number = utils.get_buffer_number()
	local buf_name = utils.get_buf_name(buffer_number)
	local handle

	if params.request_index == 0 then
		if params.starting_request_count == 1 then
			handle = M.show_progress("Pitaco", "Sending " .. buf_name .. " (" .. params.line_count .. " lines)")
		else
			handle = M.show_progress(
				"Pitaco",
				"Sending " .. buf_name .. " (split into " .. params.starting_request_count .. " requests)"
			)
		end
		params.handle = handle
	end
end

return M
