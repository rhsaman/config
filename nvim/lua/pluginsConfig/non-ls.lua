return {
  "nvimtools/none-ls.nvim",              -- configure formatters & linters
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
        }),              -- js/ts formatter
        formatting.prettier, -- js/ts formatter
        formatting.stylua, -- lua formatter
        formatting.gofumpt,
        formatting.goimports,
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
}
