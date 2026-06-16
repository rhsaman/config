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
								default = "openai/gpt-oss-120b:free",
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
							default_agent = "build",
							agent = {
								build = {
									variant = "medium",
								},
								plan = {
									variant = "medium",
								},
							},
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
	},

	-- Expand 'cc' into 'CodeCompanion' in command-line
	init = function()
		vim.cmd([[cab cc CodeCompanion]])
	end,

	config = function(_, opts)
		require("codecompanion").setup(opts)

		-- ----------------------------------------------------------------
		-- Monkey-patch: Make visual selection visible in inline prompts
		-- و visual selection که سلکت کردی رو ببینهLLM مطمئن میشه
		-- ----------------------------------------------------------------
		local Inline = require("codecompanion.interactions.inline")
		local orig_make_ext_prompts = Inline.make_ext_prompts

		function Inline:make_ext_prompts()
			local prompts = orig_make_ext_prompts(self)
			if prompts then
				for _, p in ipairs(prompts) do
					if p._meta and p._meta.tag == "visual" and p.opts then
						p.opts.visible = true
						-- Add filename to the context message for clarity
						local filename = self.buffer_context.filename or ""
						if filename ~= "" then
							p.content = p.content:gsub(
								"in the buffer",
								"in " .. filename
							)
						end
					end
				end
			end
			return prompts
		end
	end,
}
