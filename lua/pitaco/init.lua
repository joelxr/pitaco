local M = {}

local default_opts = {
	openai_model_id = "gpt-4.1-mini",
	language = "english",
	additional_instruction = nil,
	split_threshold = 100,
}

function M.setup(opts)
	opts = vim.tbl_deep_extend("force", default_opts, opts or {})
	vim.g.pitaco_openai_model_id = opts.openai_model_id
	vim.g.pitaco_language = opts.language
	vim.g.pitaco_additional_instruction = opts.additional_instruction
	vim.g.pitaco_split_threshold = opts.split_threshold
end

return M
