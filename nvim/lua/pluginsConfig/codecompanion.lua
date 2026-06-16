return {
	"olimorris/codecompanion.nvim",
	event = "VeryLazy",
	cmd = {
		"CodeCompanion",
		"CodeCompanionChat",
		"CodeCompanionCLI",
		"CodeCompanionCmd",
		"CodeCompanionActions",
	},
	keys = {
		{
			"<leader>aa",
			"<cmd>CodeCompanionChat Toggle<cr>",
			desc = "Toggle AI Chat",
			mode = { "n", "v" },
		},
		{
			"<leader>ac",
			"<cmd>CodeCompanion<cr>",
			desc = "AI Inline Prompt",
			mode = { "n", "v" },
		},
		{
			"<leader>az",
			"<cmd>CodeCompanionChat<cr>",
			desc = "New AI Chat",
			mode = { "n", "v" },
		},
		{
			"<leader>ae",
			"<cmd>CodeCompanionActions<cr>",
			desc = "AI Actions (adapters/models)",
			mode = { "n", "v" },
		},
		{
			"<leader>ag",
			"<cmd>CodeCompanion /commit<cr>",
			desc = "Generate Commit Message",
			mode = { "n", "v" },
		},
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
				show_settings = false,
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
						name = "openrouter",
						formatted_name = "OpenRouter",
						env = {
							url = "https://openrouter.ai/api",
							api_key = "OPENROUTER_API_KEY",
							chat_url = "/v1/chat/completions",
						},
						schema = {
							model = {
								default = "openrouter/free",
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
								default = "qwen/qwen3-4b", --qwen/qwen3-4b
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
						},
					},
				})
			end,
		},

		-- ---------------------------------------------------------------------------
		-- default adapter
		-- ---------------------------------------------------------------------------
		interactions = {
			chat = {
				adapter = "opencode",
				keymaps = {
					submit = {
						modes = { n = "<CR>", i = "<C-s>" },
						callback = "keymaps.send",
						description = "Submit the prompt",
					},
					-- Disable default stop (q) so q can be used for close
					stop = false,
					close = {
						modes = { n = "q", i = "<Nop>" },
						callback = "keymaps.close",
						description = "Close the chat buffer",
					},
				},
				show_tools_processing = true,
				show_context = true,
			},

			inline = {
				adapter = "opencode",
			},
			cmd = {
				adapter = "opencode",
			},
		},
	},
}
