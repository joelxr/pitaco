# Pitaco Neovim Plugin 🚀

Welcome to the **Pitaco** Neovim plugin! This is an experimental plugin designed to provide you with an AI reviewer right inside your Neovim editor. With Pitaco, you don't have to wait for the pull request AI reviewer; you can anticipate issues and improve your code before pushing to remote repositories.

## Features ✨

- **Instant Code Review**: Get immediate feedback on your code as you write.
- **AI-Powered Suggestions**: Leverage AI to enhance your coding practices.
- **Seamless Integration**: Works smoothly within Neovim.

## Installation 📦

To install Pitaco, use your preferred Neovim plugin manager. For example, with `vim-plug`:

```vim
Plug 'yourusername/pitaco'
```

Then, run `:PlugInstall` in Neovim.

## Usage 🛠️

Once installed, you can use the following commands to interact with Pitaco:

- `:PitacoReview` - Start a code review session.
- `:PitacoFeedback` - Get feedback on the current buffer.
- `:PitacoSettings` - Open the settings for Pitaco.

## Configuration ⚙️

You can configure Pitaco by adding the following to your Neovim configuration file:

```lua
require('pitaco').setup({
    apiKey = 'your-openai-api-key',
    model = 'gpt-4.1-mini',
})
```

## Contributing 🤝

Contributions are welcome! Please fork the repository and submit a pull request.

## License 📄

This project is licensed under the MIT License.

## Acknowledgments 🙏

Thanks to the Neovim community and all contributors for their support.
