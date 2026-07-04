return {
	{
		"mfussenegger/nvim-dap",
		event = "VeryLazy",
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
}
