local M = {}

function M.prepare_code_snippet(buf_nr, starting_line_number, ending_line_number)
    local lines = vim.api.nvim_buf_get_lines(buf_nr, starting_line_number - 1, ending_line_number, false)
    local max_digits = string.len(tostring(#lines + starting_line_number))

    for i, line in ipairs(lines) do
        lines[i] = string.format("%0" .. max_digits .. "d", i - 1 + starting_line_number) .. " " .. line
    end

    local text = table.concat(lines, "\n")
    return text
end

function M.get_buf_name(buf_nr)
    return vim.fn.fnamemodify(vim.fn.bufname(buf_nr), ":t")
end

return M
