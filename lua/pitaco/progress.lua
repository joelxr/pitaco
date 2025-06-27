local M = {}
local progress = require("fidget.progress")

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
end

function M.complete_progress(handle, message)
    handle:finish()
    handle:report({
        message = message,
        percentage = 100,
    })
end

function M.initialize_progress(params, buf_name)
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
