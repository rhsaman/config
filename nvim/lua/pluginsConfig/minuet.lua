return {
	"milanglacier/minuet-ai.nvim",
	version = "*",
	config = function()
		local mc = require("minuet.config")

		require("minuet").setup({
			provider = "openai_compatible",
			blink = {
				enable_auto_complete = true,
			},
			virtualtext = {
				auto_trigger_ft = { "lua", "py", "js", "ts", "go", "dart", "toml", "json" },
				keymap = {
					accept = "<C-CR>",
					accept_line = "<M-l>",
					accept_n_lines = "<M-z>",
					prev = "<M-[>",
					next = "<M-]>",
					dismiss = "<C-e>",
				},
			},
			-- Tunings for local models (slow response, limited context)
			context_window = 4096,
			throttle = 600,
			debounce = 300,
			request_timeout = 10,
			provider_options = {
				openai_compatible = {
					name = "LMStudio",
					end_point = "http://localhost:1234/v1/chat/completions",
					model = "qwen2.5-coder-3b-instruct",
					api_key = "TERM",
					optional = {
						max_tokens = 256,
						top_p = 0.9,
					},

					system = mc.default_system_prefix_first,
					chat_input = mc.default_chat_input_prefix_first,
					few_shots = mc.default_few_shots_prefix_first,
					stream = true,
				},
			},
		})
	end,
}
