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
        check_ts = true,                 -- enable treesitter
        ts_config = {
          lua = { "string" },            -- don't add pairs in lua string treesitter nodes
          javascript = { "template_string" }, -- don't add pairs in javscript template_string treesitter nodes
          java = false,                  -- don't check treesitter on java
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

  -- flutter
  {
    "akinsho/flutter-tools.nvim",
    lazy = true,
    ft = { "dart" },
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim", -- optional for vim.ui.select
    },
    keys = {
      -- flutter
      { "<leader>Fo", ":FlutterOutlineToggle<CR>", desc = "Flutter Outline",   ft = "dart" },
      { "<leader>Fe", ":FlutterEmulators<CR>",     desc = "Flutter Emulators", ft = "dart" },
      { "<leader>Fc", ":FlutterDetach<CR>",        desc = "Flutter Detach",    ft = "dart" },
      { "<leader>Fd", ":FlutterDevices<CR>",       desc = "Flutter Devices",   ft = "dart" },
      { "<leader>Fq", ":FlutterQuit<CR>",          desc = "Flutter Quit",      ft = "dart" },
      { "<leader>Fr", ":FlutterRun<CR>",           desc = "Flutter Run",       ft = "dart" },
      { "<leader>FR", ":FlutterRestart<CR>",       desc = "Flutter Restart",   ft = "dart" },
      { "<leader>Fl", ":FlutterLogToggle<CR>",     desc = "Flutter logs",      ft = "dart" },
    },
    config = function()
      require("flutter-tools").setup({
        decorations = {
          statusline = {
            -- set to true to be able use the 'flutter_tools_decorations.app_version' in your statusline
            -- this will show the current version of the flutter app from the pubspec.yaml file
            app_version = false,
            -- set to true to be able use the 'flutter_tools_decorations.device' in your statusline
            -- this will show the currently running device if an application was started with a specific
            -- device
            device = true,
            -- set to true to be able use the 'flutter_tools_decorations.project_config' in your statusline
            -- this will show the currently selected project configuration
            project_config = false,
          },
        },

        debugger = {
          -- make these two params true to enable debug mode
          enabled = true,
          run_via_dap = true,
          register_configurations = function(_)
            require("dap").adapters.dart = {
              type = "executable",
              command = vim.fn.stdpath("data") .. "/mason/bin/dart-debug-adapter",
              args = { "flutter" },
            }

            require("dap").configurations.dart = {
              {
                type = "dart",
                request = "launch",
                name = "Launch flutter",
                dartSdkPath = "home/flutter/bin/cache/dart-sdk/",
                flutterSdkPath = "home/flutter",
                program = "${workspaceFolder}/lib/main.dart",
                cwd = "${workspaceFolder}",
              },
            }
            -- uncomment below line if you've launch.json file already in your vscode setup
            -- require("dap.ext.vscode").load_launchjs()
          end,
        },
        -- flutter_path = "<full/path/if/needed>", -- <-- this takes priority over the lookup
        flutter_lookup_cmd = nil,       -- example "dirname $(which flutter)" or "asdf where flutter"
        root_patterns = { "pubspec.yaml" }, -- patterns to find the root of your flutter project
        fvm = false,                    -- takes priority over path, uses <workspace>/.fvm/flutter_sdk if enabled
        widget_guides = {
          enabled = false,
        },
        closing_tags = {
          -- highlight = "ErrorMsg", -- highlight for the closing tag
          prefix = "//", -- character to use for close tag e.g. > Widget
          enabled = true, -- set to false to disable
        },
        dev_log = {
          enabled = false,
          notify_errors = false, -- if there is an error whilst running then notify the user
          open_cmd = "30vs", -- command to use to open the log buffer
          -- open_cmd = "tabedit", -- command to use to open the log buffer
        },
        dev_tools = {
          autostart = false,    -- autostart devtools server if not detected
          auto_open_browser = false, -- Automatically opens devtools in the browser
        },
        outline = {
          open_cmd = "30vs", -- command to use to open the outline buffer
          auto_open = false, -- if true this will open the outline automatically when it is first populated
        },
        lsp = {
          color = { -- show the derived colours for dart variables
            enabled = true, -- whether or not to highlight color variables at all, only supported on flutter >= 2.10
            background = false, -- highlight the background
            background_color = nil, -- required, when background is transparent (i.e. background_color = { r = 19, g = 17, b = 24},)
            foreground = false, -- highlight the foreground
            virtual_text = true, -- show the highlight using virtual text
            virtual_text_str = "■", -- the virtual text character to highlight
          },
          settings = {
            showTodos = false,
            completeFunctionCalls = true,
            analysisExcludedFolders = { nil },
            renameFilesWithClasses = "always", -- "always"
            enableSnippets = true,
            updateImportsOnRename = true, -- Whether to update imports and other directives when files are renamed. Required for `FlutterRename` command.
          },
          -- vim.keymap.set({ "n", "v" }, "<leader>cf", vim.lsp.buf.code_action, { desc = "flutter code action" }), -- see available code actions, in visual mode will apply to selection
        },
      })
    end,
  },

  -- fugitive
  {
    "tpope/vim-fugitive",
    event = "VeryLazy",
    keys = {
      { "<leader>ga", ":Git add .<cr>",   desc = "Git add" },
      { "<leader>gc", ':Git commit -m "', desc = "Git commit" },
      { "<leader>gp", ":Git push<cr>",    desc = "Git push" },
      { "<leader>gi", "<cmd>:Git<cr>",    desc = "fugitive" },
    },
  },

  -- git sign
  {
    "lewis6991/gitsigns.nvim",
    event = "VeryLazy",
    config = true,
  },

  -- harpoon
  {
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

  --oil
  {
    "stevearc/oil.nvim",
    keys = {

      {
        "<leader>e",
        function()
          require("oil").open_float()
        end,
        desc = "Open Oil (float)",
      },
    },
    opts = {
      -- Oil will take over directory buffers (e.g. `vim .` or `:e src/`)
      -- Set to false if you want some other plugin (e.g. netrw) to open when you edit directories.
      default_file_explorer = true,
      -- Id is automatically added at the beginning, and name at the end
      -- See :help oil-columns
      columns = {
        "icon",
        -- "permissions",
        -- "size",
        -- "mtime",
      },
      -- Buffer-local options to use for oil buffers
      buf_options = {
        buflisted = false,
        bufhidden = "hide",
      },
      -- Window-local options to use for oil buffers
      win_options = {
        wrap = false,
        signcolumn = "no",
        cursorcolumn = false,
        foldcolumn = "0",
        spell = false,
        list = false,
        conceallevel = 3,
        concealcursor = "nvic",
      },
      -- Send deleted files to the trash instead of permanently deleting them (:help oil-trash)
      delete_to_trash = false,
      -- Skip the confirmation popup for simple operations (:help oil.skip_confirm_for_simple_edits)
      skip_confirm_for_simple_edits = false,
      -- Selecting a new/moved/renamed file or directory will prompt you to save changes first
      -- (:help prompt_save_on_select_new_entry)
      prompt_save_on_select_new_entry = true,
      -- Oil will automatically delete hidden buffers after this delay
      -- You can set the delay to false to disable cleanup entirely
      -- Note that the cleanup process only starts when none of the oil buffers are currently displayed
      cleanup_delay_ms = 2000,
      lsp_file_methods = {
        -- Enable or disable LSP file operations
        enabled = true,
        -- Time to wait for LSP file operations to complete before skipping
        timeout_ms = 1000,
        -- Set to true to autosave buffers that are updated with LSP willRenameFiles
        -- Set to "unmodified" to only save unmodified buffers
        autosave_changes = false,
      },
      -- Constrain the cursor to the editable parts of the oil buffer
      -- Set to `false` to disable, or "name" to keep it on the file names
      constrain_cursor = "editable",
      -- Set to true to watch the filesystem for changes and reload oil
      watch_for_changes = false,
      -- Keymaps in oil buffer. Can be any value that `vim.keymap.set` accepts OR a table of keymap
      -- options with a `callback` (e.g. { callback = function() ... end, desc = "", mode = "n" })
      -- Additionally, if it is a string that matches "actions.<name>",
      -- it will use the mapping at require("oil.actions").<name>
      -- Set to `false` to remove a keymap
      -- See :help oil-actions for a list of all available actions
      keymaps = {
        ["g?"] = { "actions.show_help", mode = "n" },
        ["<CR>"] = "actions.select",
        ["<C-v>"] = { "actions.select", opts = { vertical = true } },
        ["<C-s>"] = { "actions.select", opts = { horizontal = true } },
        ["<C-t>"] = { "actions.select", opts = { tab = true } },
        ["<C-p>"] = "actions.preview",
        ["q"] = { "actions.close", mode = "n" },
        ["<C-l>"] = "actions.refresh",
        ["-"] = { "actions.parent", mode = "n" },
        ["_"] = { "actions.open_cwd", mode = "n" },
        ["`"] = { "actions.cd", mode = "n" },
        ["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
        ["gs"] = { "actions.change_sort", mode = "n" },
        ["gx"] = "actions.open_external",
        ["g."] = { "actions.toggle_hidden", mode = "n" },
        ["g\\"] = { "actions.toggle_trash", mode = "n" },
      },
      -- Set to false to disable all of the above keymaps
      use_default_keymaps = true,
      view_options = {
        -- Show files and directories that start with "."
        show_hidden = false,
        -- This function defines what is considered a "hidden" file
        is_hidden_file = function(name, bufnr)
          local m = name:match("^%.")
          return m ~= nil
        end,
        -- This function defines what will never be shown, even when `show_hidden` is set
        is_always_hidden = function(name, bufnr)
          return false
        end,
        -- Sort file names with numbers in a more intuitive order for humans.
        -- Can be "fast", true, or false. "fast" will turn it off for large directories.
        natural_order = "fast",
        -- Sort file and directory names case insensitive
        case_insensitive = false,
        sort = {
          -- sort order can be "asc" or "desc"
          -- see :help oil-columns to see which columns are sortable
          { "type", "asc" },
          { "name", "asc" },
        },
        -- Customize the highlight group for the file name
        highlight_filename = function(entry, is_hidden, is_link_target, is_link_orphan)
          return nil
        end,
      },
      -- Extra arguments to pass to SCP when moving/copying files over SSH
      extra_scp_args = {},
      -- EXPERIMENTAL support for performing file operations with git
      git = {
        -- Return true to automatically git add/mv/rm files
        add = function(path)
          return false
        end,
        mv = function(src_path, dest_path)
          return false
        end,
        rm = function(path)
          return false
        end,
      },
      -- Configuration for the floating window in oil.open_float
      float = {
        padding = 2,
        max_width = 0.8, -- 50% of the screen width
        max_height = 0.7, -- 50% of the screen height
        border = "rounded",
        win_options = {
          winblend = 0, -- No transparency
        },
        get_win_title = nil,
        preview_split = "auto",
        override = function(conf)
          return conf
        end,
      }, -- Configuration for the file preview window
      preview_win = {
        -- Whether the preview window is automatically updated when the cursor is moved
        update_on_cursor_moved = true,
        -- How to open the preview window "load"|"scratch"|"fast_scratch"
        preview_method = "fast_scratch",
        -- A function that returns true to disable preview on a file e.g. to avoid lag
        disable_preview = function(filename)
          return false
        end,
        -- Window-local options to use for preview window buffers
        win_options = {},
      },
      -- Configuration for the floating action confirmation window
      confirmation = {
        -- Width dimensions can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
        -- min_width and max_width can be a single value or a list of mixed integer/float types.
        -- max_width = {100, 0.8} means "the lesser of 100 columns or 80% of total"
        max_width = 0.8,
        -- min_width = {40, 0.4} means "the greater of 40 columns or 40% of total"
        min_width = { 40, 0.4 },
        -- optionally define an integer/float for the exact width of the preview window
        width = nil,
        -- Height dimensions can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
        -- min_height and max_height can be a single value or a list of mixed integer/float types.
        -- max_height = {80, 0.9} means "the lesser of 80 columns or 90% of total"
        max_height = 0.7,
        -- min_height = {5, 0.1} means "the greater of 5 columns or 10% of total"
        min_height = { 5, 0.1 },
        -- optionally define an integer/float for the exact height of the preview window
        height = nil,
        border = "rounded",
        win_options = {
          winblend = 0,
        },
      },
      -- Configuration for the floating progress window
      progress = {
        max_width = 0.8,
        min_width = { 40, 0.4 },
        width = nil,
        max_height = { 10, 0.5 },
        min_height = { 5, 0.1 },
        height = nil,
        border = "rounded",
        minimized_border = "none",
        win_options = {
          winblend = 0,
        },
      },
      -- Configuration for the floating SSH window
      ssh = {
        border = "rounded",
      },
      -- Configuration for the floating keymaps help window
      keymaps_help = {
        border = "rounded",
      },
    },
    -- Optional dependencies
    dependencies = { { "echasnovski/mini.icons", opts = {} } },
    -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
  },
  --telescope
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build =
        "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5 && cmake --build build --config Release && cmake --install build --prefix build",
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

      -- تعریف میانبرها
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>fl", builtin.lsp_document_symbols, { desc = "list symbols" })
      vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "find files" })
      vim.keymap.set("n", "<leader>fs", builtin.live_grep, { desc = "search string" })
      vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "recent files" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "buffers" })
      vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "diagnostics" })
      vim.keymap.set("n", "<leader>fc", ":Telescope git_commits theme=dropdown<cr>", { desc = "git commits" })
      vim.keymap.set(
        "n",
        "<leader>fC",
        ":Telescope git_bcommits theme=dropdown<cr>",
        { desc = "git commits current file" }
      )
    end,
  },

  --theme
  {
    "rose-pine/neovim",
    name = "rose-pine",

    config = function()
      require("rose-pine").setup({
        variant = "auto",  -- auto, main, moon, or dawn
        dark_variant = "main", -- main, moon, or dawn
        dim_inactive_windows = true,
        extend_background_behind_borders = true,

        enable = {
          terminal = true,
          legacy_highlights = true, -- Improve compatibility for previous versions of Neovim
          migrations = true,   -- Handle deprecated options automatically
        },

        styles = {
          bold = true,
          italic = false,
          transparency = false,
        },

        groups = {
          border = "muted",
          link = "iris",
          panel = "surface",

          error = "love",
          hint = "iris",
          info = "foam",
          note = "pine",
          todo = "rose",
          warn = "gold",

          git_add = "foam",
          git_change = "rose",
          git_delete = "love",
          git_dirty = "rose",
          git_ignore = "muted",
          git_merge = "iris",
          git_rename = "pine",
          git_stage = "iris",
          git_text = "rose",
          git_untracked = "subtle",

          h1 = "iris",
          h2 = "foam",
          h3 = "rose",
          h4 = "gold",
          h5 = "pine",
          h6 = "foam",
        },
      })

      vim.cmd.colorscheme("rose-pine")
      vim.api.nvim_set_hl(0, "LspSignatureActiveParameter", { fg = "#ff5555", bold = true })
      -- fold color
      vim.cmd("highlight Folded guifg=#5B586E guibg=NONE ")
    end,
  },

  -- tmux navigator
  {
    "christoomey/vim-tmux-navigator", -- tmux & split window navigation
  },
}
