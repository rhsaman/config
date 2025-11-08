return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	cmd = { "Telescope" }, -- Only load when Telescope commands are used
	dependencies = {
		"nvim-lua/plenary.nvim",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			enabled = vim.fn.executable("make") == 1, -- Only load if make is available
			build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5 && cmake --build build --config Release && cmake --install build --prefix build",
		},
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")

		local default_setup = {
			defaults = {
				-- Performance optimizations
				hidden = true, -- Show hidden files
				preview = false, -- Disable preview by default for faster results
				vimgrep_arguments = {
					"rg",
					"--color=never",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
					"--smart-case",
					"--hidden", -- Include hidden files
				},
				layout_config = {
					horizontal = {
						prompt_position = "top",
						preview_width = 0.5, -- Reduce preview width for better performance
					},
				},
				mappings = {
					i = {
						["<C-k>"] = actions.move_selection_previous,
						["<C-j>"] = actions.move_selection_next,
						["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
					},
				},
				file_ignore_patterns = {
					".git/",
					"node_modules/",
					"%.jpg",
					"%.jpeg",
					"%.png",
					"%.gif",
					"%.svg",
					"%.ico",
					"%.webp",
					"%.mp4",
					"%.webm",
					"%.mov",
					"%.zip",
					"%.tar",
					"%.gz",
					"%.rar",
					"%.7z",
					"%.woff",
					"%.woff2",
					"%.ttf",
					"%.eot",
				},
			},
			pickers = {
				-- Performance-optimized pickers
				find_files = {
					theme = "dropdown",
					preview = true, -- Disable preview for file finder
					hidden = true, -- Include hidden files
				},
				live_grep = {
					theme = "dropdown",
					preview = true, -- Disable preview for grep
					additional_args = function()
						return { "--hidden" }
					end,
				},
				buffers = {
					theme = "dropdown",
					preview = true, -- Disable preview for buffer picker
					sort_lastused = true, -- Sort by last used
					mappings = {
						i = {
							["<C-d>"] = actions.delete_buffer,
						},
						n = {
							["<C-d>"] = actions.delete_buffer,
						},
					},
				},
				oldfiles = {
					theme = "dropdown",
					preview = true, -- Disable preview for oldfiles
				},
			},
			extensions = {
				fzf = {
					fuzzy = true,
					override_generic_sorter = true,
					override_file_sorter = true,
					case_mode = "smart_case",
				},
			},
		}

		-- Apply settings
		telescope.setup(default_setup)

		-- Load extension only if it's available
		if pcall(telescope.load_extension, "fzf") then
			-- Extension loaded successfully
		end
	end,
}
