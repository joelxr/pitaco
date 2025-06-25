# Pitaco Neovim Plugin 🚀

Welcome to the **Pitaco** Neovim plugin! This is an experimental plugin designed to provide you with an AI reviewer right inside your Neovim editor. With Pitaco, you don't have to wait for the pull request AI reviewer; you can anticipate issues and improve your code before pushing to remote repositories.

## Features ✨

- **Instant Code Review**: Get feedback on your code as you write.
- **AI-Powered Suggestions**: Leverage AI to enhance your coding practices.
- **Seamless Integration**: Works smoothly within Neovim.

> **Note**: Pitaco uses the native Neovim diagnostics API, making it easy to integrate with other plugins such as `folke/trouble.nvim` for enhanced diagnostics visualization.

## Installation 📦

To install Pitaco, use your preferred Neovim plugin manager. For example, with `lazy.nvim`:

```lua
require('lazy').setup({
    'joelxr/pitaco',
    dependencies = {
        'j-hui/fidget.nvim',
    }
})
```

Then, restart Neovim and run `:Lazy install`.

## Usage 🛠️

Once installed, you can use the following commands to interact with Pitaco:

- `:Pitaco` - Ask Pitaco to review your code.
- `:PitacoClear` - Clear the current review.
- `:PitacoClearLine` - Clear the current review for the current line.

## Configuration ⚙️

You can configure Pitaco by adding the following to your Neovim configuration file:

```lua
require('pitaco').setup({
	openai_model_id = "gpt-4.1-mini",
	language = "english",
	additional_instruction = nil,
	split_threshold = 100,
})
```

## Contributing 🤝

Contributions are welcome! Please fork the repository and submit a pull request.

## Roadmap 🛣️

- [ ] Support for Anthropic models
- [ ] Integration with OpenRouter
- [ ] Support for Gemini models
- [ ] Integration with Deepseek
- [ ] Support for Ollama models

## License 📄

This project is licensed under the MIT License.

## Acknowledgments 🙏

Thanks to the Neovim community and all contributors for their support.

A big thanks to [james1236/backseat.nvim](https://github.com/james1236/backseat.nvim) for inspiration.
