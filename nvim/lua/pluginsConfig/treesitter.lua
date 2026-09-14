return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "master", -- برنچ قدیمی و پایدار — به CLI جداگانه‌ی tree-sitter نیاز ندارد
		lazy = true,
		event = { "BufReadPre", "BufNewFile" },
		build = ":TSUpdate",
		dependencies = {
			"windwp/nvim-ts-autotag",
		},

		config = function()
			local treesitter = require("nvim-treesitter.configs")

			treesitter.setup({
				-- نصب خودکار پارسرها (با کامپایلر C سیستم، بدون نیاز به tree-sitter CLI)
				ensure_installed = {
					"tsx",
					"json",
					"javascript",
					"typescript",
					"yaml",
					"html",
					"css",
					"markdown",
					"markdown_inline",
					"bash",
					"lua",
					"dockerfile",
					"vim",
					"gitignore",
					"query",
					"rust",
					"go",
					"dart",
					"python",
					"c",
					"cpp",
				},

				-- هایلایت و ایندنت با treesitter
				highlight = { enable = true },
				indent = { enable = true },
			})

			-- بستن خودکار تگ‌های html/jsx
			require("nvim-ts-autotag").setup({})
		end,
	},
}
