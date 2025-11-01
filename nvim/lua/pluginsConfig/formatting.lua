return {
  "stevearc/conform.nvim",
  lazy = true,
  event = "BufReadPre",
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
        go = { "goimports", "gofumpt" },
      },
      -- format_on_save = {
      --   lsp_fallback = true,
      --   async = true, -- Enable async formatting
      --   timeout_ms = 1000,
      -- },
    })
  end,
}
