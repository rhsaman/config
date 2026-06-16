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
					accept = "<C-CR>",
					accept_line = "<M-l>",
					accept_n_lines = "<M-z>",
					prev = "<M-[>",
					next = "<M-]>",
					dismiss = "<C-e>",
				},
			},
			provider_options = {
				openai_compatible = {
					name = "LMStudio",
					end_point = "http://localhost:1234/v1/chat/completions",
					model = "qwen2.5-coder-1.5b-instruct",
					api_key = "TERM",
				},
			},
			context_window = 1024,
			throttle = 600,
			debounce = 300,
			request_timeout = 10,
			n_completions = 1,
			add_single_line_entry = false,
			-- notify = "debug",
		})
	end,
}
