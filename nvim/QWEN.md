# Neovim Configuration (LazyVim-based)

## Project Overview

This is a comprehensive Neovim configuration built on the LazyVim framework. It provides a feature-rich, IDE-like development environment with support for multiple programming languages and extensive plugin management.

### Key Features

- **Plugin Management**: Uses Lazy.nvim for efficient plugin management with lazy loading
- **Language Support**: Comprehensive LSP support for JavaScript/TypeScript, Python, Go, Rust, Dart, Lua, CSS/HTML, and more
- **Code Completion**: Powered by nvim-cmp with LSP and snippet integration
- **Syntax Highlighting**: Treesitter-based syntax highlighting and parsing
- **File Navigation**: Neo-tree file explorer with Git integration
- **Search Functionality**: Telescope-powered fuzzy finding and search
- **Git Integration**: Full Git workflow support with gitsigns and fugitive
- **AI Integration**: Codeium AI assistant integration
- **Theming**: Rose-pine theme with custom color configurations

### Architecture

The configuration follows a modular structure:

- `init.lua`: Main entry point that loads all configuration modules
- `lua/config/`: Core configuration files
  - `keymaps.lua`: All custom key mappings with leader key set to space
  - `options.lua`: Neovim options and settings
  - `lazy.lua`: Lazy plugin manager setup
  - `terminal.lua`: Terminal configuration
- `lua/pluginsConfig/`: Plugin-specific configurations
  - `core.lua`: Core plugins (autopairs, comment, indent lines, etc.)
  - `lsp.lua`: LSP server configurations for multiple languages
  - `cmp.lua`: Completion plugin setup
  - `treesitter.lua`: Treesitter parser configurations
  - `theme.lua`: Theme configuration
  - `neotree.lua`: File tree explorer
  - `formatting.lua`: Code formatting with conform.nvim
  - `harpoon.lua`: File bookmarking system
  - And many more specialized plugins

### Language-Specific Support

The configuration includes LSP servers for:
- **JavaScript/TypeScript**: ts_ls with comprehensive inlay hints
- **Python**: pyright with type checking
- **Go**: gopls with advanced analysis features
- **Rust**: rust-analyzer for modern Rust development
- **Dart**: dartls for Flutter development
- **Lua**: lua_ls with runtime awareness
- **Web Technologies**: HTML, CSS, TailwindCSS, Emmet with dedicated servers
- **Other**: YAML, JSON, Markdown, Bash, Dockerfile, etc.

### Key Mappings

- **Leader**: Space key
- **File Explorer**: `<leader>e` (Neo-tree)
- **Telescope Find Files**: `<leader>ff`
- **Telescope Live Grep**: `<leader>fs`
- **Telescope Buffers**: `<leader>fb`
- **LSP Code Actions**: `<leader>ca`
- **Go to Definition**: `gd`
- **Go to Implementation**: `gi`
- **Toggle Inlay Hints**: `<leader>i`
- **Harpoon**: Add file (`<leader>ha`), Toggle menu (`<leader>ho`), Navigate with `<C-n>`/`<C-p>`
- **Git Commands**: Various with `<leader>g` prefix
- **Window Resizing**: `<C-w>h`/`<C-w>l`/`<C-w>j`/`<C-w>k`

### Development Conventions

- Tab settings: 4 spaces for tabstop, 2 for shiftwidth
- Relative line numbers disabled, absolute enabled
- System clipboard integration enabled
- Split windows appear to the right and below
- Automatic folding based on indentation (excluding file explorers)

### Building and Running

This is a configuration directory that works with Neovim installation. To use:

1. Install Neovim (v0.9 or higher recommended)
2. Install this configuration in `~/.config/nvim`
3. Launch Neovim for automatic plugin installation
4. Install language servers using Mason or directly through your package manager
5. Install additional tools like formatters (prettier, stylua, black, etc.) as needed

### Special Notes

- The `test_code_edit.lua` file contains test code for demonstrating AI-powered code editing workflows
- Includes AI assistant integration (Codeium) with custom keymaps
- Advanced signature help with custom highlighting
- Custom fold settings for better code organization
- Git-aware development with inline signs showing changes
- Tmux navigation support for seamless terminal integration

This configuration is designed to be a complete development environment suitable for professional software development across multiple programming languages.