return {
	"yetone/avante.nvim",
	build = vim.fn.has("win32") ~= 0 and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
		or "make",
	event = "VeryLazy",
	version = false, -- Never set this value to "*"! Never!
	cmd = {
		"AvanteAsk",
		"AvanteBuild",
		"AvanteChat",
		"AvanteClear",
		"AvanteEdit",
		"AvanteFocus",
		"AvanteHistory",
		"AvanteModels",
		"AvanteRefresh",
		"AvanteShowRepoMap",
		"AvanteStop",
		"AvanteSwitchProvider",
		"AvanteToggle",
	},
	keys = {
		{ "<leader>aa", "<cmd>AvanteAsk<CR>", desc = "Ask Avante" },
		{ "<leader>az", "<cmd>lua require('avante.api').zen_mode()<CR>", desc = "Zen Mode" },
		{ "<leader>ac", "<cmd>AvanteChat<CR>", desc = "Chat with Avante" },
		{ "<leader>an", "<cmd>AvanteChatNew<CR>", desc = "New Chat with Avante" },
		{ "<leader>ae", "<cmd>AvanteEdit<CR>", desc = "Edit with Avante" },
		{ "<leader>af", "<cmd>AvanteFocus<CR>", desc = "Focus Avante" },
		{ "<leader>ah", "<cmd>AvanteHistory<CR>", desc = "Avante History" },
		{ "<leader>am", "<cmd>AvanteACPModes<CR>", desc = "Avante Mode" },
		{ "<leader>aM", "<cmd>AvanteModels<CR>", desc = "Select Avante Model" },
		{ "<leader>ap", "<cmd>AvanteSwitchProvider<CR>", desc = "Switch Avante Provider" },
		{ "<leader>ar", "<cmd>AvanteRefresh<CR>", desc = "Refresh Avante" },
		{ "<leader>as", "<cmd>AvanteStop<CR>", desc = "Stop Avante" },
		{ "<leader>at", "<cmd>AvanteToggle<CR>", desc = "Toggle Avante" },
	},
	---@module 'avante'
	opts = {
		-- add any opts here
		-- this file can contain specific instructions for your project
		instructions_file = "avante.md",
		-- for example
		provider = "openrouter",
		behaviour = {
			auto_set_keymaps = false,
		},
		providers = {
			openrouter = {
				__inherited_from = "openai",
				api_key_name = "OPENROUTER_API_KEY",
				endpoint = "https://openrouter.ai/api/v1",
				model = "openrouter/free",
				timeout = 30000,
				allow_insecure = false,
				disable_tools = true, -- openrouter/free از tool use پشتیبانی نمیکنه
				extra_request_body = {
					temperature = 0.75,
					max_tokens = 32768,
				},
			},
			-- lm_studio = {
			-- 	__inherited_from = "openai",
			-- 	endpoint = "http://localhost:1234/v1",
			-- 	model = "google/gemma-4-e2b",
			-- 	timeout = 60000,
			-- 	allow_insecure = false,
			-- 	disable_tools = false,
			-- 	extra_request_body = {},
			-- },
			-- claude = {
			-- 	endpoint = "https://api.anthropic.com",
			-- 	model = "claude-sonnet-4-20250514",
			-- 	timeout = 30000, -- Timeout in milliseconds
			-- 	extra_request_body = {
			-- 		temperature = 0.75,
			-- 		max_tokens = 20480,
			-- 	},
			-- },
			-- moonshot = {
			-- 	endpoint = "https://api.moonshot.ai/v1",
			-- 	model = "kimi-k2-0711-preview",
			-- 	timeout = 30000, -- Timeout in milliseconds
			-- 	extra_request_body = {
			-- 		temperature = 0.75,
			-- 		max_tokens = 32768,
			-- 	},
			-- },
		},
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		--- The below dependencies are optional,
		"nvim-mini/mini.pick", -- for file_selector provider mini.pick
		"nvim-telescope/telescope.nvim", -- for file_selector provider telescope
		"hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
		"ibhagwan/fzf-lua", -- for file_selector provider fzf
		"stevearc/dressing.nvim", -- for input provider dressing
		"folke/snacks.nvim", -- for input provider snacks
		"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
		"zbirenbaum/copilot.lua", -- for providers='copilot'
		{
			-- support for image pasting
			"HakonHarnes/img-clip.nvim",
			event = "VeryLazy",
			opts = {
				-- recommended settings
				default = {
					embed_image_as_base64 = false,
					prompt_for_file_name = false,
					drag_and_drop = {
						insert_mode = true,
					},
					-- required for Windows users
					use_absolute_path = true,
				},
			},
		},
		{
			-- Make sure to set this up properly if you have lazy=true
			"MeanderingProgrammer/render-markdown.nvim",
			opts = {
				file_types = { "markdown", "Avante" },
			},
			ft = { "markdown", "Avante" },
		},
	},
}
