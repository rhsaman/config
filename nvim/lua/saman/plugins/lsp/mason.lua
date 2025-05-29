return {
	"williamboman/mason.nvim",
	event = { "BufReadPre", "BufNewFile" }, -- to enable uncomment this
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		-- import mason
		local mason = require("mason")

		-- import mason-lspconfig
		local mason_lspconfig = require("mason-lspconfig")

		local mason_tool_installer = require("mason-tool-installer")

		-- enable mason and configure icons
		mason.setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		-- set up LSP servers
		mason_lspconfig.setup({
			-- list of servers for mason to install
			ensure_installed = {
				"ts_ls",
				"html",
				"cssls",
				"tailwindcss",
				"lua_ls",
				"emmet_ls",
				"pyright", -- Python LSP server
				"ruff",
				"gopls", -- Go LSP server
			},
			-- auto-install configured servers (with lspconfig)
			automatic_installation = true,
		})

		-- setup for external tools
		mason_tool_installer.setup({
			ensure_installed = {
				"golines", -- go formatter
				"gofumpt", -- go formatter
				"goimports", -- go formatter
				"black", -- python formatter
				"ruff", -- python linter
				"eslint_d", -- js/ts linter
				"prettier", -- universal formatter
				"stylua", -- lua formatter
				"dart-debug-adapter", -- dart debugger (if supported by mason-tool-installer)
			},
		})
	end,
}
