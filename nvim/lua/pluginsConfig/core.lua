return {
	{
		"mfussenegger/nvim-dap",
		event = "VeryLazy",
	},

	-- autopairs
	{
		"windwp/nvim-autopairs",
		event = "VeryLazy",

		config = function()
			local autopairs_setup, autopairs = pcall(require, "nvim-autopairs")
			if not autopairs_setup then
				return
			end
			-- configure autopairs
			autopairs.setup({
				check_ts = true, -- enable treesitter
				ts_config = {
					lua = { "string" }, -- don't add pairs in lua string treesitter nodes
					javascript = { "template_string" }, -- don't add pairs in javscript template_string treesitter nodes
					java = false, -- don't check treesitter on java
				},
			})

			-- import nvim-autopairs completion functionality safely
			local cmp_autopairs_setup, cmp_autopairs = pcall(require, "nvim-autopairs.completion.cmp")
			if not cmp_autopairs_setup then
				return
			end

			-- import nvim-cmp plugin safely (completions plugin)
			local cmp_setup, cmp = pcall(require, "cmp")
			if not cmp_setup then
				return
			end

			-- make autopairs and completion work together
			cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
		end,
	},

	-- blank indent
	{
		"lukas-reineke/indent-blankline.nvim",
		lazy = true,
		event = "VeryLazy",
		main = "ibl",
		opts = {},

		config = function()
			local highlight = { "gray" }
			local hooks = require("ibl.hooks")

			hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
				--  cappuchino
				-- vim.api.nvim_set_hl(0, "gray", { fg = "#262538" })

				-- gruvebox
				-- vim.api.nvim_set_hl(0, "gray", { fg = "#2D2D2D" })

				-- rosepine
				vim.api.nvim_set_hl(0, "gray", { fg = "#22212F" })
			end)

			require("ibl").setup({
				scope = { enabled = false },
				indent = { highlight = highlight },
			})
		end,
	},

	-- codium
	{
		"Exafunction/codeium.vim",
		event = "VeryLazy",
		config = function()
			-- Change '<C-g>' here to any keycode you like.
			vim.keymap.set("i", "<c-t>", function()
				return vim.fn["codeium#Accept"]()
			end, { expr = true, silent = true })

			vim.keymap.set("i", "<c-j>", function()
				return vim.fn["codeium#CycleCompletions"](1)
			end, { expr = true, silent = true })

			vim.keymap.set("i", "<c-k>", function()
				return vim.fn["codeium#CycleCompletions"](-1)
			end, { expr = true, silent = true })

			vim.keymap.set("n", "<c-c>", function()
				return vim.fn["codeium#Clear"]()
			end, { expr = true, silent = true })

			vim.keymap.set("n", "<leader>cc", ":CodeiumChat<CR>", { desc = "ai chat" })
		end,
	},
	-- comment
	{
		"numToStr/Comment.nvim",
		lazy = true,
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"JoosepAlviste/nvim-ts-context-commentstring",
		},
		config = function()
			-- import comment plugin safely
			local comment = require("Comment")

			local ts_context_commentstring = require("ts_context_commentstring.integrations.comment_nvim")

			-- enable comment
			comment.setup({
				-- for commenting tsx and jsx files
				pre_hook = ts_context_commentstring.create_pre_hook(),
			})
		end,
	},

	-- flutter
	{
		"akinsho/flutter-tools.nvim",
		lazy = true,
		ft = { "dart" },
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"nvim-lua/plenary.nvim",
			"stevearc/dressing.nvim", -- optional for vim.ui.select
		},
		keys = {
			-- flutter
			{ "<leader>Fo", ":FlutterOutlineToggle<CR>", desc = "Flutter Outline", ft = "dart" },
			{ "<leader>Fe", ":FlutterEmulators<CR>", desc = "Flutter Emulators", ft = "dart" },
			{ "<leader>Fc", ":FlutterDetach<CR>", desc = "Flutter Detach", ft = "dart" },
			{ "<leader>Fd", ":FlutterDevices<CR>", desc = "Flutter Devices", ft = "dart" },
			{ "<leader>Fq", ":FlutterQuit<CR>", desc = "Flutter Quit", ft = "dart" },
			{ "<leader>Fr", ":FlutterRun<CR>", desc = "Flutter Run", ft = "dart" },
			{ "<leader>FR", ":FlutterRestart<CR>", desc = "Flutter Restart", ft = "dart" },
			{ "<leader>Fl", ":FlutterLogToggle<CR>", desc = "Flutter logs", ft = "dart" },
		},
		config = function()
			require("flutter-tools").setup({
				decorations = {
					statusline = {
						-- set to true to be able use the 'flutter_tools_decorations.app_version' in your statusline
						-- this will show the current version of the flutter app from the pubspec.yaml file
						app_version = false,
						-- set to true to be able use the 'flutter_tools_decorations.device' in your statusline
						-- this will show the currently running device if an application was started with a specific
						-- device
						device = true,
						-- set to true to be able use the 'flutter_tools_decorations.project_config' in your statusline
						-- this will show the currently selected project configuration
						project_config = false,
					},
				},

				debugger = {
					-- make these two params true to enable debug mode
					enabled = true,
					run_via_dap = true,
					register_configurations = function(_)
						require("dap").adapters.dart = {
							type = "executable",
							command = vim.fn.stdpath("data") .. "/mason/bin/dart-debug-adapter",
							args = { "flutter" },
						}

						require("dap").configurations.dart = {
							{
								type = "dart",
								request = "launch",
								name = "Launch flutter",
								dartSdkPath = "home/flutter/bin/cache/dart-sdk/",
								flutterSdkPath = "home/flutter",
								program = "${workspaceFolder}/lib/main.dart",
								cwd = "${workspaceFolder}",
							},
						}
						-- uncomment below line if you've launch.json file already in your vscode setup
						-- require("dap.ext.vscode").load_launchjs()
					end,
				},
				-- flutter_path = "<full/path/if/needed>", -- <-- this takes priority over the lookup
				flutter_lookup_cmd = nil, -- example "dirname $(which flutter)" or "asdf where flutter"
				root_patterns = { "pubspec.yaml" }, -- patterns to find the root of your flutter project
				fvm = false, -- takes priority over path, uses <workspace>/.fvm/flutter_sdk if enabled
				widget_guides = {
					enabled = false,
				},
				closing_tags = {
					-- highlight = "ErrorMsg", -- highlight for the closing tag
					prefix = "//", -- character to use for close tag e.g. > Widget
					enabled = true, -- set to false to disable
				},
				dev_log = {
					enabled = false,
					notify_errors = false, -- if there is an error whilst running then notify the user
					open_cmd = "30vs", -- command to use to open the log buffer
					-- open_cmd = "tabedit", -- command to use to open the log buffer
				},
				dev_tools = {
					autostart = false, -- autostart devtools server if not detected
					auto_open_browser = false, -- Automatically opens devtools in the browser
				},
				outline = {
					open_cmd = "30vs", -- command to use to open the outline buffer
					auto_open = false, -- if true this will open the outline automatically when it is first populated
				},
				lsp = {
					color = { -- show the derived colours for dart variables
						enabled = true, -- whether or not to highlight color variables at all, only supported on flutter >= 2.10
						background = false, -- highlight the background
						background_color = nil, -- required, when background is transparent (i.e. background_color = { r = 19, g = 17, b = 24},)
						foreground = false, -- highlight the foreground
						virtual_text = true, -- show the highlight using virtual text
						virtual_text_str = "■", -- the virtual text character to highlight
					},
					settings = {
						showTodos = false,
						completeFunctionCalls = true,
						analysisExcludedFolders = { nil },
						renameFilesWithClasses = "always", -- "always"
						enableSnippets = true,
						updateImportsOnRename = true, -- Whether to update imports and other directives when files are renamed. Required for `FlutterRename` command.
					},
					-- vim.keymap.set({ "n", "v" }, "<leader>cf", vim.lsp.buf.code_action, { desc = "flutter code action" }), -- see available code actions, in visual mode will apply to selection
				},
			})
		end,
	},

	-- fugitive
	{
		"tpope/vim-fugitive",
		cmd = { "Git", "Gdiffsplit", "Gvdiffsplit", "Gread", "Gwrite", "Ggrep", "GMove", "GDelete", "GRename" },
		keys = {
			{ "<leader>ga", ":Git add .<cr>", desc = "Git add", silent = true },
			{ "<leader>gc", ':Git commit -m "', desc = "Git commit", silent = true },
			{ "<leader>gp", ":Git push<cr>", desc = "Git push", silent = true },
			{ "<leader>gi", "<cmd>:Git<cr>", desc = "fugitive", silent = true },
		},
	},

	-- git sign
	{
		"lewis6991/gitsigns.nvim",
		event = "VeryLazy",
		config = true,
	},

	-- tmux navigator
	{

		"christoomey/vim-tmux-navigator", -- tmux & split window navigation
	},

	-- lualine
	{
		"nvim-lualine/lualine.nvim",
		lazy = true,
		event = { "BufReadPre", "BufNewFile" },
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			local lualine = require("lualine")
			local lazy_status = require("lazy.status") -- to configure lazy pending updates count

			-- configure lualine with modified theme
			lualine.setup({
				options = {
					theme = "auto",
				},
				sections = {
					lualine_x = {
						{
							lazy_status.updates,
							cond = lazy_status.has_updates,
							-- color = { fg = "#ff9e64" },
						},
						-- { "encoding" },
						-- { "fileformat" },
						{ "filetype" },
					},
					lualine_a = { { "filename", file_status = true, path = 1 } },
				},
			})
		end,
	},

	-- tmux navigator
	{
		"christoomey/vim-tmux-navigator", -- tmux & split window navigation
	},
}
