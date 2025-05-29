return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
  },
  config = function()
    -- import lspconfig plugin
    local lspconfig = require("lspconfig")

    -- import cmp-nvim-lsp plugin
    local cmp_nvim_lsp = require("cmp_nvim_lsp")

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

    -- inlay_hint
    vim.keymap.set("n", "<leader>i", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
    end, { desc = "Toggle inlay hints" })

    -- used to enable autocompletion (assign to every lsp server config)
    local capabilities = cmp_nvim_lsp.default_capabilities()

    local on_attach = function(client, _)
      -- Optionally disable formatting if another plugin is handling it
      if client.server_capabilities.documentFormattingProvider then
        client.server_capabilities.documentFormattingProvider = false
      end
    end

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
}
