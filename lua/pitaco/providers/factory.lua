local M = {}

function M.create_provider(provider_name)
	if provider_name == "openai" then
		return require("pitaco.providers.openai")
	end

	if provider_name == "anthropic" then
		return require("pitaco.providers.anthropic")
	end

	if provider_name == "openrouter" then
		return require("pitaco.providers.openrouter")
	end

	if provider_name == "ollama" then
		return require("pitaco.providers.ollama")
	end

	error("Invalid provider name: " .. provider_name)
end

return M
