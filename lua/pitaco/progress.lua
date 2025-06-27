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

return M
