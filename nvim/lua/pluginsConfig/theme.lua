return {
	"catppuccin/nvim",
	name = "catppuccin",

	config = function()
		require("catppuccin").setup({
			flavour = "mocha",
			background = {
				light = "latte",
				dark = "mocha",
			},
			dim_inactive = {
				enabled = true,
			},
			transparent_background = false,
			show_end_of_buffer = false,
			term_colors = true,

			styles = {
				bold = true,
				italic = false,
			},

			integrations = {
				telescope = true,
				lualine = true,
				gitsigns = true,
				indent_blankline = {
					enabled = true,
				},
				native_lsp = {
					enabled = true,
				},
			},
		})

		vim.cmd.colorscheme("catppuccin")
		-- fold color
		vim.cmd("highlight Folded guifg=#585B70 guibg=NONE ")
	end,
}
