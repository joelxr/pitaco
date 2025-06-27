local M = {}

function M.get_language()
	return vim.g.pitaco_language
end

function M.get_additional_instruction()
	return vim.g.pitaco_additional_instruction or ""
end

function M.get_split_threshold()
	return vim.g.pitaco_split_threshold
end

return M
