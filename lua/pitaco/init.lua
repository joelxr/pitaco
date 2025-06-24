local M = {}

local default_opts = {
	openai_model_id = "gpt-4.1-mini",
	language = "english",
	additional_instruction = nil,
	split_threshold = 100,
}

function M.setup(opts)
	-- Merge default_opts with opts
	opts = vim.tbl_deep_extend("force", default_opts, opts or {})

	-- if vim.g.backseat_openai_model_id == nil then
	vim.g.backseat_openai_model_id = opts.openai_model_id
	-- end

	-- if vim.g.backseat_language == nil then
	vim.g.backseat_language = opts.language
	-- end

	-- if vim.g.backseat_additional_instruction == nil then
	vim.g.backseat_additional_instruction = opts.additional_instruction
	-- end

	-- if vim.g.backseat_split_threshold == nil then
	vim.g.backseat_split_threshold = opts.split_threshold
	-- end
end

return M
