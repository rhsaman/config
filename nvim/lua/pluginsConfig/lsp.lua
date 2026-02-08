return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
	},
	config = function()
		local capabilities = require("cmp_nvim_lsp").default_capabilities()
		vim.lsp.config("*", {
			capabilities = capabilities,
		})

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				local map = function(keys, func, desc)
					vim.keymap.set("n", keys, func, { buffer = ev.buf, desc = "Lsp: " .. desc })
				end
			end,
		})
		-- Set up custom highlighting for signature help
		vim.api.nvim_set_hl(0, "LspSignatureActiveParameter", {
			bg = "#3e4451",
			fg = "#e06c75",
			bold = true,
			underline = true,
		})

		-- Change the Diagnostic symbols in the sign column (gutter)
		vim.diagnostic.config({
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = "",
					[vim.diagnostic.severity.WARN] = "",
					[vim.diagnostic.severity.HINT] = "󰌵",
					[vim.diagnostic.severity.INFO] = "",
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
		vim.lsp.config("html", {})
		vim.lsp.enable("html")

		-- configure typescript server with plugin
		vim.lsp.config("ts_ls", {
			cmd = { "typescript-language-server", "--stdio" },
			filetypes = {
				"javascript",
				"javascriptreact",
				"javascript.jsx",
				"typescript",
				"typescriptreact",
				"typescript.tsx",
			},
			root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
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
		vim.lsp.enable("ts_ls")

		-- configure css server
		vim.lsp.config("cssls", {})
		vim.lsp.enable("cssls")

		-- configure tailwindcss server
		vim.lsp.config("tailwindcss", {
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
		vim.lsp.enable("tailwindcss")

		-- configure emmet language server
		vim.lsp.config("emmet_ls", {
			filetypes = { "html", "css", "scss", "javascriptreact", "typescriptreact" },
			init_options = {
				html = {
					options = {
						["bem.enabled"] = true,
					},
				},
			},
		})
		vim.lsp.enable("emmet_ls")

		-- golang
		vim.lsp.config("gopls", {
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
		vim.lsp.enable("gopls")

		-- rust
		vim.lsp.config("rust_analyzer", {
			cmd = {
				"rustup",
				"run",
				"stable",
				"rust-analyzer",
			},
		})
		vim.lsp.enable("rust_analyzer")

		-- python
		vim.lsp.config("pyright", {
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
		vim.lsp.enable("pyright")

		-- lua server (with special settings)
		vim.lsp.config("lua_ls", {
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
		vim.lsp.enable("lua_ls")

		-- dart
		vim.lsp.config("dartls", {
			cmd = { "dart", "language-server", "--protocol=lsp" },
			filetypes = { "dart" },
			root_dir = require("lspconfig.util").root_pattern("pubspec.yaml", ".git"),
			settings = {
				dart = {
					completeFunctionCalls = true,
					showTodos = false,
				},
			},
		})
		vim.lsp.enable("dartls")

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
