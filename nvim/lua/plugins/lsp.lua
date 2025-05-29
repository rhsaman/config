-- lsp
return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
	},
	config = function()
		-- import lspconfig plugin
		local lspconfig = require("lspconfig")

		-- import cmp-nvim-lsp plugin
		local cmp_nvim_lsp = require("cmp_nvim_lsp")

		local capabilities = cmp_nvim_lsp.default_capabilities()
		local on_attach = function(client, bufnr)
			if vim.lsp.buf_is_attached(bufnr, client.id) then
				return
			end
			-- Optionally disable formatting if another plugin is handling it
			if client.server_capabilities.documentFormattingProvider then
				client.server_capabilities.documentFormattingProvider = false
			end
		end

		-- Change the Diagnostic symbols in the sign column (gutter)
		vim.diagnostic.config({
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = " ",
					[vim.diagnostic.severity.WARN] = " ",
					[vim.diagnostic.severity.HINT] = "󰌵 ",
					[vim.diagnostic.severity.INFO] = " ",
				},
			},
			virtual_text = { current_line = true },
			underline = true,
		})

		-- Trigger signature help automatically when typing '(' or ',' in insert mode
		local signature_lock = false
		vim.api.nvim_create_autocmd("InsertCharPre", {
			pattern = "*",
			callback = function()
				local char = vim.v.char
				if (char == "(" or char == ",") and not signature_lock then
					signature_lock = true

					vim.defer_fn(function()
						vim.lsp.buf.signature_help()
						signature_lock = false
					end, 100) -- تاخیر 100 میلی‌ثانیه کافی و امن است
				end
			end,
		})

		-- configure html server
		vim.lsp.config("html", {
			capabilities = capabilities,
			on_attach = on_attach,
		})

		-- configure typescript server with plugin
		vim.lsp.config("ts_ls", {
			capabilities = capabilities,
			on_attach = on_attach,
			settings = {
				typescript = {
					inlayHints = {
						includeInlayEnumMemberValueHints = true,
						includeInlayFunctionLikeReturnTypeHints = true,
						includeInlayFunctionParameterTypeHints = true,
						includeInlayParameterNameHints = "all",
						includeInlayParameterNameHintsWhenArgumentMatchesName = false,
						includeInlayPropertyDeclarationTypeHints = true,
						includeInlayVariableTypeHints = true,
					},
				},
				javascript = {
					inlayHints = {
						includeInlayEnumMemberValueHints = true,
						includeInlayFunctionLikeReturnTypeHints = true,
						includeInlayFunctionParameterTypeHints = true,
						includeInlayParameterNameHints = "all",
						includeInlayParameterNameHintsWhenArgumentMatchesName = false,
						includeInlayPropertyDeclarationTypeHints = true,
						includeInlayVariableTypeHints = true,
					},
				},
			},
		})

		-- configure css server
		vim.lsp.config("cssls", {
			capabilities = capabilities,
			on_attach = on_attach,
		})

		-- configure tailwindcss server
		vim.lsp.config("tailwindcss", {
			capabilities = capabilities,
			on_attach = on_attach,
			cmd = { "tailwindcss-language-server", "--stdio" },
			filetypes = {
				"aspnetcorerazor",
				"astro",
				"astro-markdown",
				"blade",
				"clojure",
				"django-html",
				"htmldjango",
				"edge",
				"eelixir",
				"elixir",
				"ejs",
				"erb",
				"eruby",
				"gohtml",
				"gohtmltmpl",
				"haml",
				"handlebars",
				"hbs",
				"html",
				"htmlangular",
				"html-eex",
				"heex",
				"jade",
				"leaf",
				"liquid",
				"markdown",
				"mdx",
				"mustache",
				"njk",
				"nunjucks",
				"php",
				"razor",
				"slim",
				"twig",
				"css",
				"less",
				"postcss",
				"sass",
				"scss",
				"stylus",
				"sugarss",
				"javascript",
				"javascriptreact",
				"reason",
				"rescript",
				"typescript",
				"typescriptreact",
				"vue",
				"svelte",
				"templ",
			},
			settings = {
				tailwindCSS = {
					classAttributes = { "class", "className", "class:list", "classList", "ngClass" },
					includeLanguages = {
						eelixir = "html-eex",
						elixir = "phoenix-heex",
						eruby = "erb",
						heex = "phoenix-heex",
						htmlangular = "html",
						templ = "html",
					},
					lint = {
						cssConflict = "warning",
						invalidApply = "error",
						invalidConfigPath = "error",
						invalidScreen = "error",
						invalidTailwindDirective = "error",
						invalidVariant = "error",
						recommendedVariantOrder = "warning",
					},
					validate = true,
				},
			},
			workspace_required = true,
		})

		-- configure emmet language server
		vim.lsp.enable("emmet_ls", {
			capabilities = capabilities,
			on_attach = on_attach,
			filetypes = { "html", "css", "scss", "javascriptreact", "typescriptreact" },
			init_options = {
				html = {
					options = {
						["bem.enabled"] = true,
					},
				},
			},
		})

		-- golang
		vim.lsp.config("gopls", {
			capabilities = capabilities,
			on_attach = on_attach,
			cmd = { "gopls" },
			filetypes = { "go", "gomod", "gowork", "gotmpl" },
			settings = {
				gopls = {
					analyses = {
						unusedparams = true,
					},
					gofumpt = true, -- enables gofumpt instead of gofmt
					["local"] = "", -- optional: for import grouping
					usePlaceholders = false,
					staticcheck = true,
					hints = {
						assignVariableTypes = true,
						compositeLiteralFields = true,
						compositeLiteralTypes = true,
						constantValues = true,
						functionTypeParameters = true,
						parameterNames = true,
						rangeVariableTypes = true,
					},
				},
			},
		})

		-- rust
		vim.lsp.config("rust_analyzer", {
			capabilities = capabilities,
			on_attach = on_attach,
			cmd = {
				"rustup",
				"run",
				"stable",
				"rust-analyzer",
			},
		})

		-- python
		vim.lsp.config("pyright", {
			capabilities = capabilities,
			on_attach = on_attach,
			filetypes = { "python" },
			settings = {
				pyright = {
					disableOrganizeImports = false,
					analysis = {
						diagnosticMode = "workspace",
						typeCheckingMode = "off",
						useLibraryCodeForTypes = true,
					},
				},
			},
		})

		-- lua server (with special settings)
		vim.lsp.config("lua_ls", {
			capabilities = capabilities,
			on_attach = on_attach,
			settings = { -- custom settings for lua
				Lua = {
					-- make the language server recognize "vim" global
					diagnostics = {
						globals = { "vim" },
					},
					workspace = {
						-- make language server aware of runtime files
						library = {
							[vim.fn.expand("$VIMRUNTIME/lua")] = true,
							[vim.fn.stdpath("config") .. "/lua"] = true,
						},
					},
				},
			},
		})

		-- dart
		vim.lsp.config("dartls", {
			on_attach = on_attach,
			settings = {
				dart = {
					-- dartExcludedFolders = {
					-- 	vim.fn.expand("$HOME/AppData/Local/Pub/Cache"),
					-- 	vim.fn.expand("$HOME/.pub-cache"),
					-- 	vim.fn.expand("/opt/homebrew/"),
					-- 	vim.fn.expand("$HOME/tools/flutter/"),
					-- },
				},
			},
		})

		-- kubernetes
		vim.lsp.config("yamlls", {
			settings = {
				yaml = {
					schemas = { kubernetes = "globPattern" },
				},
			},
		})
	end,
}
