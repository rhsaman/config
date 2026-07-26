return {
	"akinsho/bufferline.nvim",
	event = "VeryLazy",
	version = "*",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	keys = {
		{ "<M-l>", "<cmd>BufferLineCycleNext<CR>", desc = "next tab" },
		{ "<M-h>", "<cmd>BufferLineCyclePrev<CR>", desc = "previous tab" },
		{ "<M-S-l>", "<cmd>BufferLineMoveNext<CR>", desc = "move tab right" },
		{ "<M-S-h>", "<cmd>BufferLineMovePrev<CR>", desc = "move tab left" },
		{ "<leader>tc", "<cmd>BufferLineCloseOthers<CR>", desc = "close other buffers" },
		{ "<leader>tl", "<cmd>BufferLineCloseRight<CR>", desc = "close right buffers" },
		{ "<leader>th", "<cmd>BufferLineCloseLeft<CR>", desc = "close left buffers" },
	},
	config = function()
		require("bufferline").setup({
			options = {
				mode = "buffers",
				always_show_bufferline = true,
				separator_style = "slant",
				hover = { enabled = true, delay = 200 },
				offsets = { { filetype = "neo-tree", text = "Explorer" } },
			},
		})
	end,
}
