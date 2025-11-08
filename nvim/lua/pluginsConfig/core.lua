return {
	{
		"mfussenegger/nvim-dap",
		event = "VeryLazy",
	},

	-- autopairs
	{
		"windwp/nvim-autopairs",
		event = "VeryLazy",

		config = function()
			local autopairs_setup, autopairs = pcall(require, "nvim-autopairs")
			if not autopairs_setup then
				return
			end
			-- configure autopairs
			autopairs.setup({
				check_ts = true, -- enable treesitter
				ts_config = {
					lua = { "string" }, -- don't add pairs in lua string treesitter nodes
					javascript = { "template_string" }, -- don't add pairs in javscript template_string treesitter nodes
					java = false, -- don't check treesitter on java
				},
			})

			-- import nvim-autopairs completion functionality safely
			local cmp_autopairs_setup, cmp_autopairs = pcall(require, "nvim-autopairs.completion.cmp")
			if not cmp_autopairs_setup then
				return
			end

			-- import nvim-cmp plugin safely (completions plugin)
			local cmp_setup, cmp = pcall(require, "cmp")
			if not cmp_setup then
				return
			end

			-- make autopairs and completion work together
			cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
		end,
	},

	-- blank indent
	{
		"lukas-reineke/indent-blankline.nvim",
		lazy = true,
		event = "VeryLazy",
		main = "ibl",
		opts = {},

		config = function()
			local highlight = { "gray" }
			local hooks = require("ibl.hooks")

			hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
				--  cappuchino
				-- vim.api.nvim_set_hl(0, "gray", { fg = "#262538" })

				-- gruvebox
				-- vim.api.nvim_set_hl(0, "gray", { fg = "#2D2D2D" })

				-- rosepine
				vim.api.nvim_set_hl(0, "gray", { fg = "#22212F" })
			end)

			require("ibl").setup({
				scope = { enabled = false },
				indent = { highlight = highlight },
			})
		end,
	},

	-- codium
	{
		"Exafunction/codeium.vim",
		event = "VeryLazy",
		config = function()
			-- Change '<C-g>' here to any keycode you like.
			vim.keymap.set("i", "<c-t>", function()
				return vim.fn["codeium#Accept"]()
			end, { expr = true, silent = true })

			vim.keymap.set("i", "<c-j>", function()
				return vim.fn["codeium#CycleCompletions"](1)
			end, { expr = true, silent = true })

			vim.keymap.set("i", "<c-k>", function()
				return vim.fn["codeium#CycleCompletions"](-1)
			end, { expr = true, silent = true })

			vim.keymap.set("n", "<c-c>", function()
				return vim.fn["codeium#Clear"]()
			end, { expr = true, silent = true })

			vim.keymap.set("n", "<leader>cc", ":CodeiumChat<CR>", { desc = "ai chat" })
		end,
	},
	-- comment
	{
		"numToStr/Comment.nvim",
		lazy = true,
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"JoosepAlviste/nvim-ts-context-commentstring",
		},
		config = function()
			-- import comment plugin safely
			local comment = require("Comment")

			local ts_context_commentstring = require("ts_context_commentstring.integrations.comment_nvim")

			-- enable comment
			comment.setup({
				-- for commenting tsx and jsx files
				pre_hook = ts_context_commentstring.create_pre_hook(),
			})
		end,
	},

	-- fugitive
	{
		"tpope/vim-fugitive",
		cmd = { "Git", "Gdiffsplit", "Gvdiffsplit", "Gread", "Gwrite", "Ggrep", "GMove", "GDelete", "GRename" },
		keys = {
			{ "<leader>ga", ":Git add .<cr>", desc = "Git add", silent = true },
			{ "<leader>gc", ':Git commit -m "', desc = "Git commit", silent = true },
			{ "<leader>gp", ":Git push<cr>", desc = "Git push", silent = true },
			{ "<leader>gi", "<cmd>:Git<cr>", desc = "fugitive", silent = true },
		},
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

	-- tmux navigator
	{
		"christoomey/vim-tmux-navigator", -- tmux & split window navigation
	},
}
