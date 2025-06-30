# Pitaco Neovim Plugin 🚀

Welcome to the **Pitaco** Neovim plugin! This is an experimental plugin designed to provide you with an AI reviewer right inside your Neovim editor. With Pitaco, you can anticipate issues and improve your code before pushing to remote repositories.

## Features ✨

- **Code Review**: Get feedback on your code.
- **AI-Powered Suggestions**: Leverage LLMs to enhance your coding practices.
- **Seamless Integration**: Works smoothly within Neovim.

> **Note**: Pitaco uses the native Neovim diagnostics API, making it easy to integrate with other plugins such as `folke/trouble.nvim` for enhanced diagnostics visualization.

## Installation 📦

To install Pitaco, use your preferred Neovim plugin manager. For example, with `lazy.nvim`:

```lua
require('lazy').setup({
    'joelxr/pitaco.nvim',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'j-hui/fidget.nvim',
    },
    config = function()
        require('pitaco').setup({
            -- minimal configuration, see below for more options
            openai_model_id = "gpt-4.1-mini",
            provider = "openai",
        })
    end,
})
```

Then, restart Neovim and run `:Lazy install`.

Pitaco has the following dependencies:
- `nvim-lua/plenary.nvim`
- `j-hui/fidget.nvim`
- `curl`

## Usage 🛠️

Once installed, you can use the following commands to interact with Pitaco:

- `:Pitaco` - Ask Pitaco to review your code.
- `:PitacoClear` - Clear the current review.
- `:PitacoClearLine` - Clear the current review for the current line.

## Configuration ⚙️

To use Pitaco, you need to set up one of the following environment variables, depending on your LLM API provider:

- `OPENAI_API_KEY` - For OpenAI API.
- `ANTHROPIC_API_KEY` - For Anthropic API.
- `OPENROUTER_API_KEY` - For OpenRouter API.

Those keys are required to authenticate requests. You can set it in your shell configuration file (e.g., `.bashrc`, `.zshrc`):

Exmaple:

```bash
export OPENAI_API_KEY="your-openai-api-key"
export ANTHROPIC_API_KEY="your-anthropic-api-key"
export OPENROUTER_API_KEY="your-openrouter-api-key"
```

> **Disclaimer**: Currently, Pitaco only supports those providers. However, support for additional models is planned in the roadmap.

You can configure Pitaco by adding the following to your Neovim configuration file:

```lua
require('pitaco').setup({
    openai_model_id = "gpt-4.1-mini",
    anthropic_model_id = "claude-3-5-haiku-latest",
    openrouter_model_id = "openrouter/deepseek/deepseek-chat-v3-0324:free",
    provider = "anthropic", -- "openai", "anthropic", "openrouter"
    language = "english",
    additional_instruction = nil,
    split_threshold = 100,
})
```

### Diagnostics UI (Optional)

If you want you can setup better UI for diagnostics on Neovim, you can:
 - use [folke/trouble.nvim](https://github.com/folke/trouble.nvim) to show the diagnostics in a different panel and leverage all the features of it
 - have a mapping to `vim.diagnostic.open_float` to show the diagnostics in a floating window of the current line
 - setup the editor to display custom icons and colors for diagnostics
 - setup Pitaco to run when the buffer is loaded or saved (I would only recommend this if you are using a free model like the ones provided by OpenRouter)

See example below of those options:

```lua
-- Example of a mapping to show the diagnostics in the current line
vim.keymap.set("n", "<leader>do", vim.diagnostic.open_float)
````

```lua
-- Example of better diagnostics on buffer with icons and colors
vim.diagnostic.config({
    signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = " ",
			[vim.diagnostic.severity.WARN] = " ",
			[vim.diagnostic.severity.INFO] = " ",
			[vim.diagnostic.severity.HINT] = "󰠠 ",
		},
		linehl = {
			[vim.diagnostic.severity.ERROR] = "Error",
			[vim.diagnostic.severity.WARN] = "Warn",
			[vim.diagnostic.severity.INFO] = "Info",
			[vim.diagnostic.severity.HINT] = "Hint",
		},
	},
    severity_sort = true,
    float = true,
})
```

```lua
-- Example of how to setup Pitaco to run on file open
vim.api.nvim_create_autocmd("BufRead", {
	callback = function()
		local fileType = vim.bo.filetype
        local desiredFileTypes = { "javascript", "typescript", "vue", "html", "markdown", "python", "rust", "go", "java", "c", "cpp", "lua" }
        
		if vim.tbl_contains(desiredFileTypes, fileType) then
			vim.cmd("Pitaco")
		end
	end,
})
```

## Contributing 🤝

Contributions are welcome! Please fork the repository and submit a pull request.

## Roadmap 🛣️

- [x] Support for Anthropic models
- [x] Integration with OpenRouter
- [ ] Support for Gemini models
- [ ] Integration with Deepseek
- [ ] Support for Ollama models

## License 📄

This project is licensed under the MIT License.

## Acknowledgments 🙏

Thanks to the Neovim community and all contributors for their support.

A big thanks to [james1236/backseat.nvim](https://github.com/james1236/backseat.nvim) for inspiration.
