local M = {}

function M.create_provider(provider_name)
	if provider_name == "openai" then
    return require("pitaco.providers.openai")
	end
	error("Invalid provider name: " .. provider_name)
end

return M
