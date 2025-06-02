return {
	"ThePrimeagen/harpoon",
	config = function()
		require("harpoon").setup({
			global_settings = {
				save_on_toggle = true,
				save_on_change = true,
				enter_on_sendcmd = false,
				tmux_autoclose_windows = true,
				excluded_filetypes = { "harpoon" },
				mark_branch = true,
				tabline = false,
				tabline_prefix = "  ",
				tabline_suffix = "  ",
			},
		})
	end,
}
