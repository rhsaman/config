return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	event = "VeryLazy",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5 && cmake --build build --config Release && cmake --install build --prefix build",
		},
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")

		local default_setup = {
			defaults = {
				path_display = { "truncate" },
				mappings = {
					i = {
						["<C-k>"] = actions.move_selection_previous,
						["<C-j>"] = actions.move_selection_next,
						["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
					},
				},
				file_ignore_patterns = {
					".git",
					"node_modules",
					"%.mp4",
					"%.jpg",
					"vendor",
					"%.png",
					"%.jpeg",
					"%.gif",
					"%.woff",
					"%.woff2",
				},
			},
			pickers = {},
			extensions = {
				fzf = {
					fuzzy = true,
					override_generic_sorter = true,
					override_file_sorter = true,
					case_mode = "smart_case",
				},
			},
		}

		-- بررسی پروژه فلاتر (وجود pubspec.yaml)
		if vim.fn.filereadable("pubspec.yaml") == 1 then
			default_setup.pickers = {
				find_files = {
					cwd = vim.fn.getcwd() .. "/lib/",
					theme = "dropdown",
				},
				live_grep = {
					cwd = vim.fn.getcwd() .. "/lib/",
					theme = "dropdown",
				},
				oldfiles = {
					theme = "dropdown",
				},
				buffers = {
					theme = "dropdown",
				},
			}
		else
			default_setup.pickers = {
				find_files = {
					theme = "dropdown",
				},
				live_grep = {
					theme = "dropdown",
				},
				oldfiles = {
					theme = "dropdown",
				},
				buffers = {
					theme = "dropdown",
				},
			}
		end

		-- اعمال تنظیمات
		telescope.setup(default_setup)

		telescope.load_extension("fzf")
	end,
}
