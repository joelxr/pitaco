local M = {}

local progress_state = {
	percentage = 0,
	current_request = 0,
	total_requests = 0,
	running = false,
	message = "",
}

function M.stop()
	progress_state.running = false
  progress_state.percentage = 100
  progress_state.current_request = 0
  progress_state.total_requests = 0
  progress_state.message = ""
end

function M.update(message, current_request, total_requests)
  progress_state.running = true
	progress_state.percentage = math.floor((current_request / total_requests) * 100)
	progress_state.current_request = current_request
	progress_state.total_requests = total_requests
	progress_state.message = message
end

function M.get_state()
	return progress_state
end

return M
