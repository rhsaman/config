return {
	"milanglacier/minuet-ai.nvim",
	version = "*",
	config = function()
		require("minuet").setup({
			provider = "openai_compatible",
			blink = {
				enable_auto_complete = true,
			},
			virtualtext = {
				auto_trigger_ft = { "*" },
				keymap = {
					accept = "<M-CR>",
					accept_line = "<M-l>",
					accept_n_lines = "<M-z>",
					prev = "<M-[>",
					next = "<M-]>",
					dismiss = "<C-e>",
				},
			},
			-- Tunings for local models (slow response, limited context)
			context_window = 2048,
			throttle = 600,
			debounce = 300,
			request_timeout = 10,
			provider_options = {
				openai_compatible = {
					name = "LMStudio",
					end_point = "http://localhost:1234/v1/chat/completions",
					model = "qwen2.5-coder-3b-instruct",
					api_key = "TERM",
					max_tokens = 512,
					temperature = 0.1,
					top_p = 0.9,
					frequency_penalty = 0.0,
					presence_penalty = 0.0,
					stop = {},
					stream = true,
				},
			},
		})
	end,
}
