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

function M.get_openai_model()
	local model = vim.g.pitaco_openai_model_id

	if model ~= nil then
		return model
	end

	if vim.g.pitaco_model_id_complained == nil then
		local message = "No model specified. Please set openai_model_id in the setup table. Using default value for now"
		vim.fn.confirm(message, "&OK", 1, "Warning")
		vim.g.pitaco_model_id_complained = 1
	end

	return "gpt-4.1-mini"
end

return M
