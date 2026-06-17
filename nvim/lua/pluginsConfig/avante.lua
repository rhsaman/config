return {
	"yetone/avante.nvim",
	event = "VeryLazy",
	lazy = true,
	version = false,
	build = "make",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		"nvim-tree/nvim-web-devicons",
		{
			"MeanderingProgrammer/render-markdown.nvim",
			opts = {
				file_types = { "markdown", "Avante" },
			},
			ft = { "markdown", "Avante" },
		},
	},
	opts = {
		provider = "opencode",
		auto_suggestions_provider = "lm_studio",
		mode = "agentic",
		providers = {
			["lm_studio"] = {
				__inherited_from = "openai",
				endpoint = "http://localhost:1234/v1",
				model = "qwen2.5-coder-3b-instruct",
				api_key_name = "",
				disable_tools = true,
			},
			-- ["openrouter"] = {
			-- 	__inherited_from = "openai",
			-- 	endpoint = "https://openrouter.ai/api/v1",
			-- 	model = "openrouter/free",
			-- 	api_key_name = "OPENROUTER_API_KEY",
			-- 	disable_tools = true,
			-- },
		},
		acp_providers = {
			["opencode"] = {
				command = "opencode",
				args = { "acp" },
			},
		},
		behaviour = {
			auto_suggestions = false,
			auto_set_keymaps = true,
			auto_set_highlight_group = true,
		},
		-- Suggestion keymaps removed — using minuet for inline completion instead
		windows = {
			position = "right",
			width = 50,
		},
		highlights = {
			diff = {
				current = "DiffAdd",
			},
		},
	},
	config = function(_, opts)
		require("avante").setup(opts)
	end,
}
