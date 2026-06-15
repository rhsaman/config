return {
	"olimorris/codecompanion.nvim",
	version = "^19.0.0",
	event = "VeryLazy",
	cmd = {
		"CodeCompanion",
		"CodeCompanionChat",
		"CodeCompanionCLI",
		"CodeCompanionCmd",
		"CodeCompanionActions",
	},
	keys = {
		{ "<leader>aa", "<cmd>CodeCompanionChat Toggle<cr>", desc = "Toggle AI Chat", mode = { "n", "v" } },
		{ "<leader>ac", "<cmd>CodeCompanion<cr>", desc = "AI Inline Prompt", mode = { "n", "v" } },
		{ "<leader>az", "<cmd>CodeCompanionChat<cr>", desc = "New AI Chat", mode = { "n", "v" } },
		{ "<leader>ae", "<cmd>CodeCompanionActions<cr>", desc = "AI Actions (adapters/models)", mode = { "n", "v" } },
		{ "<leader>ag", "<cmd>CodeCompanion /commit<cr>", desc = "Generate Commit Message", mode = { "n", "v" } },
		{ "ga", "<cmd>CodeCompanionChat Add<cr>", desc = "Add to AI Chat", mode = "v" },
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"hrsh7th/nvim-cmp",
		{
			"MeanderingProgrammer/render-markdown.nvim",
			opts = {
				file_types = { "markdown", "codecompanion" },
			},
			ft = { "markdown", "codecompanion" },
		},
	},
	opts = {
		-- MCP Server برای DuckDuckGo Web Search
		mcp = {
			servers = {
				["duckduckgo"] = {
					cmd = { "npx", "-y", "mcp-duckduckgo" },
				},
			},
			opts = {
				default_servers = { "duckduckgo" },
			},
		},
		display = {
			action_palette = {
				provider = "telescope",
			},
			chat = {
				show_settings = true,
				show_token_count = true,
				show_tools_processing = true,
			},
		},

		-- ---------------------------------------------------------------------------
		-- تنظمات منطبق با providerهایی که توی avante.lua داری
		-- ---------------------------------------------------------------------------
		adapters = {
			http = {
				-- OpenRouter (مشابه اون چیزی که توی avante.lua داری)
				openrouter = function()
					return require("codecompanion.adapters").extend("openai_compatible", {
						env = {
							url = "https://openrouter.ai/api",
							api_key = "OPENROUTER_API_KEY",
							chat_url = "/v1/chat/completions",
						},
						schema = {
							model = {
								default = "openrouter/free",
								choices = {
									["openrouter/free"] = {},
									["openai/gpt-oss-120b:free"] = {},
								},
							},
						},
					})
				end,

				-- LM Studio (مدل محلی)
				lm_studio = function()
					return require("codecompanion.adapters").extend("openai_compatible", {
						env = {
							url = "http://localhost:1234",
							api_key = "TERM",
							chat_url = "/v1/chat/completions",
						},
						schema = {
							model = {
								default = "qwen2.5-coder-1.5b-instruct",
							},
						},
					})
				end,
			},
		},

		-- ---------------------------------------------------------------------------
		-- ACP Adapters (Agent Client Protocol)
		-- ---------------------------------------------------------------------------
		acp = {
			opencode = function()
				return require("codecompanion.adapters").extend("opencode", {
					defaults = {
						session_config_options = {
							model = "deepseek-v4-flash-free",
							mode = "build",
						},
					},
				})
			end,
		},

		-- ---------------------------------------------------------------------------
		-- adapter پیش‌فرض
		-- ---------------------------------------------------------------------------
		-- نکته: Inline فقط HTTP adapter پشتیبانی می‌کنه، پس ACP (opencode) براش کار نمی‌کنه
		-- نکته: Chat با HTTP adapter (openrouter) استریم میشه و جواب رو لحظه‌ای می‌بینی
		--        ولی ACP (opencode) لودینگ نشون نمیده و تا آخر جواب صبر می‌کنه
		interactions = {
			chat = {
				adapter = "opencode",
			},
			inline = {
				adapter = "openrouter",
			},
			cmd = {
				adapter = "opencode",
			},
			background = {
				adapter = "opencode",
			},

		},

		-- ---------------------------------------------------------------------------
		-- custom keymaps inside chat buffer
		-- ---------------------------------------------------------------------------
		keymaps = {
			-- submit = {
			-- 	modes = { n = "<CR>", i = "<C-s>" },
			-- },
		},

		prompt_library = {
			["Commit message"] = {
				interaction = "chat",
				description = "Generate and apply a commit message",
				opts = {
					alias = "commit",
					auto_submit = true,
					adapter = {
						name = "lm_studio",
						model = "qwen/qwen3-4b",
					},
				},
				tools = { "run_command" },
				prompts = {
					{
						role = "user",
						content = function()
							local diff = vim
								.system({ "git", "diff", "--no-ext-diff", "--staged" }, { text = true })
								:wait()
								.stdout
							if diff == "" then
								return "No staged changes found. Please stage your files first with `git add`."
							end
							return string.format(
								"You are an expert at following the Conventional Commit specification. Given the git diff listed below, generate a commit message, then run `git commit -m \"<message>\"` with the message inline. Do NOT run bare `git commit` without -m. If the message has multiple lines, use `-m` for the subject and `-m` for the body.\n\n```diff\n%s\n```",
								diff
							)
						end,
					},
				},
			},
		},

	},

	-- Expand 'cc' into 'CodeCompanion' in command-line
	init = function()
		vim.cmd([[cab cc CodeCompanion]])
	end,

	-- تنظیمات بعد از لود شدن plugin (شامل status indicator برای ACP)
	config = function(_, opts)
		require("codecompanion").setup(opts)

		-- ── Status indicator برای ACP chat (چون لودینگ نداره) ──
		local Group = vim.api.nvim_create_augroup("CodeCompanionStatus", { clear = true })
		local request_active = false

		vim.api.nvim_create_autocmd("User", {
			group = Group,
			pattern = "ChatSubmitted",
			callback = function(args)
				if args.data and args.data.type == "acp" then
					request_active = true
					vim.notify("🤖 Runing...", vim.log.levels.INFO, {
						title = "CodeCompanion",
						timeout = false,
					})
				end
			end,
		})

		vim.api.nvim_create_autocmd("User", {
			group = Group,
			pattern = "ChatDone",
			callback = function()
				if request_active then
					request_active = false
					vim.notify("✅ Completed", vim.log.levels.INFO, {
						title = "CodeCompanion",
						timeout = 3000,
					})
				end
			end,
		})

		vim.api.nvim_create_autocmd("User", {
			group = Group,
			pattern = "ChatStopped",
			callback = function()
				if request_active then
					request_active = false
					vim.notify("⏹️ Stopped!", vim.log.levels.WARN, {
						title = "CodeCompanion",
						timeout = 3000,
					})
				end
			end,
		})
	end,
}
