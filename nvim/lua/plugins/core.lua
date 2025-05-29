return {
  {
    "mfussenegger/nvim-dap",
    event = "VeryLazy",
  },

  -- lsp
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      inlay_hints = { enabled = false },
    },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      { "antosha417/nvim-lsp-file-operations", config = true },
    },
    config = function()
      -- import lspconfig plugin
      local lspconfig = require("lspconfig")

      -- import cmp-nvim-lsp plugin
      local cmp_nvim_lsp = require("cmp_nvim_lsp")

      local capabilities = cmp_nvim_lsp.default_capabilities()
      local on_attach = function(client, bufnr)
        if vim.lsp.buf_is_attached(bufnr, client.id) then
          return
        end
        -- Optionally disable formatting if another plugin is handling it
        if client.server_capabilities.documentFormattingProvider then
          client.server_capabilities.documentFormattingProvider = false
        end
      end

      -- Change the Diagnostic symbols in the sign column (gutter)
      vim.diagnostic.config({
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = "󰌵 ",
            [vim.diagnostic.severity.INFO] = " ",
          },
        },
        virtual_text = { current_line = true },
        underline = true,
      })

      -- Trigger signature help automatically when typing '(' or ',' in insert mode
      local signature_lock = false
      vim.api.nvim_create_autocmd("InsertCharPre", {
        pattern = "*",
        callback = function()
          local char = vim.v.char
          if (char == "(" or char == ",") and not signature_lock then
            signature_lock = true

            vim.defer_fn(function()
              vim.lsp.buf.signature_help()
              signature_lock = false
            end, 100) -- تاخیر 100 میلی‌ثانیه کافی و امن است
          end
        end,
      })

      -- configure html server
      lspconfig["html"].setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })

      -- configure typescript server with plugin
      lspconfig["ts_ls"].setup({
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          typescript = {
            inlayHints = {
              includeInlayEnumMemberValueHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayParameterNameHints = "all",
              includeInlayParameterNameHintsWhenArgumentMatchesName = false,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayVariableTypeHints = true,
            },
          },
          javascript = {
            inlayHints = {
              includeInlayEnumMemberValueHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayParameterNameHints = "all",
              includeInlayParameterNameHintsWhenArgumentMatchesName = false,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayVariableTypeHints = true,
            },
          },
        },
      })

      -- configure css server
      lspconfig["cssls"].setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })

      -- configure tailwindcss server
      lspconfig["tailwindcss"].setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })

      -- configure emmet language server
      lspconfig.emmet_ls.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        filetypes = { "html", "css", "scss", "javascriptreact", "typescriptreact" },
        init_options = {
          html = {
            options = {
              ["bem.enabled"] = true,
            },
          },
        },
      })

      -- golang
      lspconfig.gopls.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        cmd = { "gopls" },
        filetypes = { "go", "gomod", "gowork", "gotmpl" },
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
            },
            gofumpt = true, -- enables gofumpt instead of gofmt
            ["local"] = "", -- optional: for import grouping
            usePlaceholders = false,
            staticcheck = true,
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              compositeLiteralTypes = true,
              constantValues = true,
              functionTypeParameters = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
          },
        },
      })

      -- rust
      lspconfig.rust_analyzer.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        cmd = {
          "rustup",
          "run",
          "stable",
          "rust-analyzer",
        },
      })

      -- python
      lspconfig.pyright.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        filetypes = { "python" },
        settings = {
          pyright = {
            disableOrganizeImports = false,
            analysis = {
              diagnosticMode = "workspace",
              typeCheckingMode = "off",
              useLibraryCodeForTypes = true,
            },
          },
        },
      })

      -- lua server (with special settings)
      lspconfig["lua_ls"].setup({
        capabilities = capabilities,
        on_attach = on_attach,
        settings = { -- custom settings for lua
          Lua = {
            -- make the language server recognize "vim" global
            diagnostics = {
              globals = { "vim" },
            },
            workspace = {
              -- make language server aware of runtime files
              library = {
                [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                [vim.fn.stdpath("config") .. "/lua"] = true,
              },
            },
          },
        },
      })

      -- dart
      lspconfig.dartls.setup({
        on_attach = on_attach,
        settings = {
          dart = {
            -- dartExcludedFolders = {
            -- 	vim.fn.expand("$HOME/AppData/Local/Pub/Cache"),
            -- 	vim.fn.expand("$HOME/.pub-cache"),
            -- 	vim.fn.expand("/opt/homebrew/"),
            -- 	vim.fn.expand("$HOME/tools/flutter/"),
            -- },
          },
        },
      })

      -- kubernetes
      lspconfig.yamlls.setup({
        settings = {
          yaml = {
            schemas = { kubernetes = "globPattern" },
          },
        },
      })
    end,
  },

  -- mason
  {
    "williamboman/mason.nvim",
    event = { "BufReadPre", "BufNewFile" }, -- to enable uncomment this
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
    config = function()
      -- import mason
      local mason = require("mason")

      -- import mason-lspconfig
      local mason_lspconfig = require("mason-lspconfig")

      local mason_tool_installer = require("mason-tool-installer")

      -- enable mason and configure icons
      mason.setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      })

      -- set up LSP servers
      mason_lspconfig.setup({
        -- list of servers for mason to install
        ensure_installed = {
          "ts_ls",
          "html",
          "cssls",
          "tailwindcss",
          "lua_ls",
          "emmet_ls",
          "pyright", -- Python LSP server
          "ruff",
          "gopls", -- Go LSP server
        },
        -- auto-install configured servers (with lspconfig)
        automatic_installation = true,
      })

      -- setup for external tools
      mason_tool_installer.setup({
        ensure_installed = {
          "golines",       -- go formatter
          "gofumpt",       -- go formatter
          "goimports",     -- go formatter
          "black",         -- python formatter
          "ruff",          -- python linter
          "eslint_d",      -- js/ts linter
          "prettier",      -- universal formatter
          "stylua",        -- lua formatter
          "dart-debug-adapter", -- dart debugger (if supported by mason-tool-installer)
        },
      })
    end,
  },

  --non-ls
  {
    "nvimtools/none-ls.nvim",             -- configure formatters & linters
    event = { "BufReadPre", "BufNewFile" }, -- to enable uncomment this
    dependencies = {
      "jay-babu/mason-null-ls.nvim",
    },
    config = function()
      local mason_null_ls = require("mason-null-ls")

      local null_ls = require("null-ls")

      local null_ls_utils = require("null-ls.utils")

      mason_null_ls.setup({
        ensure_installed = {
          "prettier", -- prettier formatter
          "stylua", -- lua formatter
          "black", -- python formatter
          "eslint_d", -- js linter
        },
      })

      -- for conciseness
      local formatting = null_ls.builtins.formatting -- to setup formatters
      -- local diagnostics = null_ls.builtins.diagnostics -- to setup linters

      -- to setup format on save
      local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

      -- configure null_ls
      null_ls.setup({
        -- add package.json as identifier for root (for typescript monorepos)
        root_dir = null_ls_utils.root_pattern(
          ".null-ls-root",
          "package.json",
          "main.py",
          "app.py",
          "go.mod",
          "main.dart",
          "Makefile",
          ".git"
        ),
        -- setup formatters & linters
        sources = {
          --  to disable file types use
          --  "formatting.prettier.with({disabled_filetypes: {}})" (see null-ls docs)
          formatting.prettier.with({
            -- extra_filetypes = { "svelte" },
          }),             -- js/ts formatter
          formatting.prettier, -- js/ts formatter
          formatting.stylua, -- lua formatter
          formatting.gofumpt,
          formatting.goimports,
          formatting.golines,
          formatting.black,
          -- null_ls.builtins.diagnostics.eslint_d,
        },
        on_attach = function(current_client, bufnr)
          -- configure format on save
          if current_client.supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = augroup,
              buffer = bufnr,
              callback = function()
                vim.lsp.buf.format({
                  -- filter = function(client)
                  -- 	--  only use null-ls for formatting instead of lsp server
                  -- 	return client.name == "null-ls"
                  -- end,
                  bufnr = bufnr,
                })
              end,
            })
          end
        end,
      })
    end,
  },

  --auto session
  {
    "rmagatti/auto-session",
    event = "VimEnter", -- change event to "VimEnter" for auto-session
    config = function()
      local auto_session = require("auto-session")

      auto_session.setup({
        silent_restore = true,
        -- auto_session_enable_last_session = true,
        -- auto_session_enabled = true,
        auto_save_enabled = true,
        auto_restore_enabled = true,
        log_level = "error",
        -- auto_session_suppress_dirs = { "~/"},
      })

      -- If you intend to apply session options:
      -- vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
    end,
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

  -- cmp
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-buffer",        -- source for text in buffer
      "hrsh7th/cmp-path",          -- source for file system paths
      "L3MON4D3/LuaSnip",          -- snippet engine
      "saadparwaiz1/cmp_luasnip",  -- for autocompletion
      "rafamadriz/friendly-snippets", -- useful snippets
      "onsails/lspkind.nvim",      -- vs-code like pictograms
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local lspkind = require("lspkind")

      -- Load snippets
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        completion = {
          completeopt = "menu,menuone,noselect",
        },
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-k>"] = cmp.mapping.select_prev_item(), -- Previous suggestion
          ["<C-j>"] = cmp.mapping.select_next_item(), -- Next suggestion
          ["<C-d>"] = cmp.mapping.scroll_docs(-4),
          ["<C-u>"] = cmp.mapping.scroll_docs(4),
          ["<C-o>"] = cmp.mapping.complete(),           -- Show suggestions
          ["<C-e>"] = cmp.mapping.abort(),              -- Close suggestions
          ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Confirm selection
          -- Keep <Tab> as a fallback for default behavior
          ["<Tab>"] = cmp.mapping(function(fallback)
            if luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback() -- Perform normal tabbing
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback() -- Perform normal shift-tabbing
            end
          end, { "i", "s" }),
        }), -- Sources for autocompletion
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          -- { name = "luasnip" }, -- Snippets
        }, {
          { name = "buffer" },
        }),
        -- Formatting for pictograms
        formatting = {
          format = lspkind.cmp_format({
            mode = "symbol",
            maxwidth = 50,
            ellipsis_char = "...",
          }),
        },
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
  -- formatting
  {
    "stevearc/conform.nvim",
    lazy = true,
    event = { "BufReadPre", "BufNewFile" }, -- to disable, comment this out
    config = function()
      local conform = require("conform")

      conform.setup({
        formatters_by_ft = {
          javascript = { "prettier" },
          typescript = { "prettier" },
          javascriptreact = { "prettier" },
          typescriptreact = { "prettier" },
          svelte = { "prettier" },
          css = { "prettier" },
          html = { "prettier" },
          json = { "prettier" },
          yaml = { "prettier" },
          markdown = { "prettier" },
          graphql = { "prettier" },
          lua = { "stylua" },
          python = { "isort", "black" },
          go = { "goimports", "golines", "gofumpt" },
        },
        format_on_save = {
          lsp_fallback = true,
          async = false,
          timeout_ms = 1000,
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

  --todo comment
  {
    --  usage
    -- TODO: do something
    -- FIX: this should be fixed
    -- HACK: weird code warning
    -- NOTE:
    -- TEST:

    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    lazy = true,
    event = { "VeryLazy" },
    keys = {
      { "<leader>ft", ":TodoTelescope theme=dropdown<cr>", desc = "TODO List" },
      { "<leader>tt", ":TodoTrouble<cr>",                  desc = "TODO List" },
    },
    opts = {
      signs = true,   -- show icons in the signs column
      sign_priority = 8, -- sign priority
      -- keywords recognized as todo comments
      keywords = {
        FIX = {
          icon = " ", -- icon used for the sign, and in search results
          color = "error", -- can be a hex color, or a named color (see below)
          alt = { "FIXME", "BUG", "FIXIT", "ISSUE" }, -- a set of other keywords that all map to this FIX keywords
          -- signs = false, -- configure signs for some keywords individually
        },
        TODO = { icon = " ", color = "info" },
        HACK = { icon = " ", color = "warning" },
        WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
        PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
        NOTE = { icon = " ", color = "#22863A", alt = { "INFO" } },
        TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
      },
      gui_style = {
        fg = "NONE",      -- The gui style to use for the fg highlight group.
        bg = "BOLD",      -- The gui style to use for the bg highlight group.
      },
      merge_keywords = true, -- when true, custom keywords will be merged with the defaults
      -- highlighting of the line containing the todo comment
      -- * before: highlights before the keyword (typically comment characters)
      -- * keyword: highlights of the keyword
      -- * after: highlights after the keyword (todo text)
      highlight = {
        multiline = true,            -- enable multine todo comments
        multiline_pattern = "^.",    -- lua pattern to match the next multiline from the start of the matched keyword
        multiline_context = 10,      -- extra lines that will be re-evaluated when changing a line
        before = "",                 -- "fg" or "bg" or empty
        keyword = "wide",            -- "fg", "bg", "wide", "wide_bg", "wide_fg" or empty. (wide and wide_bg is the same as bg, but will also highlight surrounding characters, wide_fg acts accordingly but with fg)
        after = "fg",                -- "fg" or "bg" or empty
        pattern = [[.*<(KEYWORDS)\s*:]], -- pattern or table of patterns, used for highlighting (vim regex)
        comments_only = true,        -- uses treesitter to match keywords in comments only
        max_line_len = 400,          -- ignore lines longer than this
        exclude = {},                -- list of file types to exclude highlighting
      },
      -- list of named colors where we try to extract the guifg from the
      -- list of highlight groups or use the hex color if hl not found as a fallback
      colors = {
        error = { "DiagnosticError", "ErrorMsg", "#DC2626" },
        warning = { "DiagnosticWarn", "WarningMsg", "#FBBF24" },
        info = { "DiagnosticInfo", "#2795EB" },
        hint = { "DiagnosticHint", "#10B981" },
        default = { "Identifier", "#7C6AED" },
        test = { "Identifier", "#FF00FF" },
      },
      search = {
        command = "rg",
        args = {
          "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
        },
        -- regex that will be used to match keywords.
        -- don't replace the (KEYWORDS) placeholder
        pattern = [[\b(KEYWORDS):]], -- ripgrep regex
        -- pattern = [[\b(KEYWORDS)\b]], -- match without the extra colon. You'll likely get false positives
      },
    },
  },

  --treesitter context
  {

    "nvim-treesitter/nvim-treesitter-context",
    lazy = true,
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("treesitter-context").setup({
        enable = true,
        max_lines = 0,
        min_window_height = 0,
        line_numbers = true,
        multiline_threshold = 20,
        trim_scope = "outer",
        mode = "topline",
        separator = "-",
        zindex = 20,
        on_attach = nil,
      })
    end,
  },

  -- treesitter
  {
    {
      "nvim-treesitter/nvim-treesitter",
      lazy = true,
      event = { "BufReadPre", "BufNewFile" },
      build = ":TSUpdate",
      dependencies = {
        "nvim-treesitter/nvim-treesitter-textobjects",
        "windwp/nvim-ts-autotag",
      },

      config = function()
        local treesitter = require("nvim-treesitter.configs")

        -- configure treesitter
        treesitter.setup({ -- enable syntax highlighting
          -- rainbow = {
          -- 	enable = true,
          -- 	query = {
          -- 		"rainbow-parens",
          -- 		html = "rainbow-tags",
          -- 		latex = "rainbow-blocks",
          -- 	},
          -- 	-- strategy = rainbow.strategy.global,
          -- },
          highlight = {
            enable = true,
            additional_vim_regex_highlighting = true,
          },
          -- enable indentation
          indent = { enable = true },
          -- enable autotagging (w/ nvim-ts-autotag plugin)
          autotag = {
            enable = true,
          },
          -- ensure these language parsers are installed
          ensure_installed = {
            "json",
            "javascript",
            "typescript",
            -- "tsx",
            "yaml",
            "html",
            "css",
            -- "prisma",
            "markdown",
            "markdown_inline",
            -- "svelte",
            -- "graphql",
            "bash",
            "lua",
            "dockerfile",
            "vim",
            "gitignore",
            "query",
            -- "rust",
            "go",
            "dart",
            "python",
          },

          incremental_selection = {
            enable = true,
          },
          -- enable nvim-ts-context-commentstring plugin for commenting tsx and jsx
          ts_context_commentstring = {
            enable = true,
            enable_autocmd = false,
            config = {
              javascript = {
                __default = "// %s",
                jsx_element = "{/* %s */}",
                jsx_fragment = "{/* %s */}",
                jsx_attribute = "// %s",
                comment = "// %s",
              },
            },
          },
        })
      end,
    },
  },

  -- trouble
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },

    opts = {
      auto_close = false,   -- auto close when there are no items
      auto_open = false,    -- auto open when there are items
      auto_preview = true,  -- automatically open preview when on an item
      auto_refresh = true,  -- auto refresh when open
      auto_jump = false,    -- auto jump to the item when there's only one
      focus = true,         -- Focus the window when opened
      restore = true,       -- restores the last location in the list when opening
      follow = true,        -- Follow the current item
      indent_guides = true, -- show indent guides
      max_items = 200,      -- limit number of items that can be displayed per section
      multiline = true,     -- render multi-line messages
      pinned = false,       -- When pinned, the opened trouble window will be bound to the current buffer
      warn_no_results = true, -- show a warning when there are no results
      open_no_results = false, -- open the trouble window when there are no results
      win = {},             -- window options for the results window. Can be a split or a floating window.
      -- Window options for the preview window. Can be a split, floating window,
      -- or `main` to show the preview in the main editor window.
      preview = {
        type = "main",
        -- when a buffer is not yet loaded, the preview window will be created
        -- in a scratch buffer with only syntax highlighting enabled.
        -- Set to false, if you want the preview to always be a real loaded buffer.
        scratch = true,
      },
      -- Throttle/Debounce settings. Should usually not be changed.
      ---@type table<string, number|{ms:number, debounce?:boolean}>
      throttle = {
        refresh = 20,                        -- fetches new data when needed
        update = 10,                         -- updates the window
        render = 10,                         -- renders the window
        follow = 100,                        -- follows the current item
        preview = { ms = 100, debounce = true }, -- shows the preview for the current item
      },
      -- Key mappings can be set to the name of a builtin action,
      -- or you can define your own custom action.
      keys = {
        ["?"] = "help",
        r = "refresh",
        R = "toggle_refresh",
        q = "close",
        o = "jump_close",
        ["<esc>"] = "cancel",
        ["<cr>"] = "jump",
        ["<2-leftmouse>"] = "jump",
        ["<c-s>"] = "jump_split",
        ["<c-v>"] = "jump_vsplit",
        -- go down to next item (accepts count)
        -- j = "next",
        ["}"] = "next",
        ["]]"] = "next",
        -- go up to prev item (accepts count)
        -- k = "prev",
        ["{"] = "prev",
        ["[["] = "prev",
        dd = "delete",
        d = { action = "delete", mode = "v" },
        i = "inspect",
        p = "preview",
        P = "toggle_preview",
        zo = "fold_open",
        zO = "fold_open_recursive",
        zc = "fold_close",
        zC = "fold_close_recursive",
        za = "fold_toggle",
        zA = "fold_toggle_recursive",
        zm = "fold_more",
        zM = "fold_close_all",
        zr = "fold_reduce",
        zR = "fold_open_all",
        zx = "fold_update",
        zX = "fold_update_all",
        zn = "fold_disable",
        zN = "fold_enable",
        zi = "fold_toggle_enable",
        gb = { -- example of a custom action that toggles the active view filter
          action = function(view)
            view:filter({ buf = 0 }, { toggle = true })
          end,
          desc = "Toggle Current Buffer Filter",
        },
        s = { -- example of a custom action that toggles the severity
          action = function(view)
            local f = view:get_filter("severity")
            local severity = ((f and f.filter.severity or 0) + 1) % 5
            view:filter({ severity = severity }, {
              id = "severity",
              template = "{hl:Title}Filter:{hl} {severity}",
              del = severity == 0,
            })
          end,
          desc = "Toggle Severity Filter",
        },
      },
      modes = {
        -- sources define their own modes, which you can use directly,
        -- or override like in the example below
        lsp_references = {
          -- some modes are configurable, see the source code for more details
          params = {
            include_declaration = true,
          },
        },
        -- The LSP base mode for:
        -- * lsp_definitions, lsp_references, lsp_implementations
        -- * lsp_type_definitions, lsp_declarations, lsp_command
        lsp_base = {
          params = {
            -- don't include the current location in the results
            include_current = false,
          },
        },
        -- more advanced example that extends the lsp_document_symbols
        symbols = {
          desc = "document symbols",
          mode = "lsp_document_symbols",
          focus = false,
          win = { position = "right" },
          filter = {
            -- remove Package since luals uses it for control flow structures
            ["not"] = { ft = "lua", kind = "Package" },
            any = {
              -- all symbol kinds for help / markdown files
              ft = { "help", "markdown" },
              -- default set of symbol kinds
              kind = {
                "Class",
                "Constructor",
                "Enum",
                "Field",
                "Function",
                "Interface",
                "Method",
                "Module",
                "Namespace",
                "Package",
                "Property",
                "Struct",
                "Trait",
              },
            },
          },
        },
      },
      -- stylua: ignore
      icons = {
        indent        = {
          top         = "│ ",
          middle      = "├╴",
          last        = "└╴",
          -- last          = "-╴",
          -- last       = "╰╴", -- rounded
          fold_open   = " ",
          fold_closed = " ",
          ws          = "  ",
        },
        folder_closed = " ",
        folder_open   = " ",
        kinds         = {
          Array         = " ",
          Boolean       = "󰨙 ",
          Class         = " ",
          Constant      = "󰏿 ",
          Constructor   = " ",
          Enum          = " ",
          EnumMember    = " ",
          Event         = " ",
          Field         = " ",
          File          = " ",
          Function      = "󰊕 ",
          Interface     = " ",
          Key           = " ",
          Method        = "󰊕 ",
          Module        = " ",
          Namespace     = "󰦮 ",
          Null          = " ",
          Number        = "󰎠 ",
          Object        = " ",
          Operator      = " ",
          Package       = " ",
          Property      = " ",
          String        = " ",
          Struct        = "󰆼 ",
          TypeParameter = " ",
          Variable      = "󰀫 ",
        },
      },
    },

    cmd = "Trouble",
    keys = {
      {
        "<leader>td",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics",
      },
      {
        "<leader>ts",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols",
      },
      {
        "<leader>tl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references",
      },
      {
        "<leader>tq",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List",
      },
    },
  },

  --whichkey
  {

    "folke/which-key.nvim",
    lazy = true,
    event = "VeryLazy",
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
    config = function()
      local wk = require("which-key")
      wk.add({
        { "<leader>f", group = "file" }, -- group
        { "gr",        group = "code" }, -- group
        { "<leader>h", group = "harpoon" }, -- group
        { "<leader>b", group = "buffer" },
        { "<leader>a", group = "avante ai" },
        { "<leader>g", group = "git" },
        { "<leader>F", group = "flutter" },
        { "<leader>T", group = "tab" },
        { "<leader>w", group = "session" },
        { "<leader>s", group = "pane" },
        { "<leader>c", group = "code" },
        { "<leader>j", group = "terminal" },
        { "<leader>t", group = "Trouble" },
      })
    end,
  },
}
