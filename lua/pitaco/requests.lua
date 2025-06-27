local progress = require("pitaco.progress")

local M = {}

function M.parse_response(response, buffer_number, params)
    local lines = vim.split(response.choices[1].message.content, "\n")
    local diagnostics = {}
    local suggestions = {}

    for _, line in ipairs(lines) do
        if (string.sub(line, 1, 5) == "line=") or string.sub(line, 1, 6) == "lines=" then
            table.insert(suggestions, line)
        elseif #suggestions > 0 then
            suggestions[#suggestions] = suggestions[#suggestions] .. "\n" .. line
        end
    end

    if #suggestions ~= 0 then
        progress.complete_progress(
            params.handle,
            #suggestions .. " suggestion(s) using " .. response.usage.total_tokens .. " tokens"
        )
    end

    for _, suggestion in ipairs(suggestions) do
        local line_string = string.sub(suggestion, 6, string.find(suggestion, ":") - 1)
        if string.find(line_string, "-") ~= nil then
            line_string = string.sub(line_string, 1, string.find(line_string, "-") - 1)
        end
        local line_num = tonumber(line_string)

        if line_num == nil then
            line_num = 1
        end
        local message = string.sub(suggestion, string.find(suggestion, ":") + 1, string.len(suggestion))
        if string.sub(message, 1, 1) == " " then
            message = string.sub(message, 2, string.len(message))
        end
        table.insert(diagnostics, {
            lnum = line_num - 1,
            col = 0,
            message = message,
            severity = vim.diagnostic.severity.INFO,
            source = "pitaco",
        })
    end

    vim.diagnostic.set(params.namespace, buffer_number, diagnostics, {})
end

return M
