return {
	"milanglacier/minuet-ai.nvim",
	version = "*",
	config = function()
		local mc = require("minuet.config")

		require("minuet").setup({
			provider = "openai_fim_compatible",
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
			n_completions = 1,
			context_window = 8192,
			throttle = 200,
			debounce = 100,
			request_timeout = 10,
			provider_options = {
				openai_fim_compatible = {
					end_point = "http://localhost:1234/v1/completions",
					model = "deepseek-coder-1.3b-instruct",
					api_key = "TERM",
					name = "LMStudio",
					stream = true,
					template = require("minuet.config").default_fim_template,
					optional = {
						max_tokens = 256,
					},
				},
			},
		})
	end,
}
