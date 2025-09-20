return {
	{
		"dccsillag/magma-nvim",
		run = ":UpdateRemotePlugins",
		build = function()
			vim.cmd("UpdateRemotePlugins")
		end,
		config = function()
			vim.g.magma_automatically_open_output = false
			vim.g.magma_output_window_borders = false
			vim.g.magma_cell_highlight_group = "CursorLine"
			vim.g.magma_save_path = vim.fn.stdpath("data") .. "/magma"
			vim.g.magma_show_mimetype_debug = false
		end,
		keys = {
			{ "<leader>mi", ":MagmaInit<CR>", desc = "Init Magma" },
			{ "<leader>me", ":MagmaEvaluateLine<CR>", desc = "Evaluate line" },
			{ "<leader>mr", ":MagmaReevaluateCell<CR>", desc = "Reevaluate cell" },
			{ "<leader>md", ":MagmaDelete<CR>", desc = "Delete cell" },
			{ "<leader>mo", ":MagmaShowOutput<CR>", desc = "Show output" },
			{ "<leader>ms", ":MagmaRestart!<CR>", desc = "Restart kernel" },
			{ "<leader>mv", ":<C-u>MagmaEvaluateVisual<CR>", desc = "Evaluate visual", mode = "v" },
		},
	},
}