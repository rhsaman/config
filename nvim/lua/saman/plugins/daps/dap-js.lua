return {
  "mxsdev/nvim-dap-vscode-js",
  ft = { "javascriptreact", "javascript", "typescript" },
  -- opt = true,
  dependencies = { "mfussenegger/nvim-dap" },

  config = function()
    require("dap-vscode-js").setup({
      debugger_path = "/Users/saman/vscode-js-debug", -- مسیر به درستی ست شده
      adapters = { "pwa-node" },
    })

    local dap = require("dap")

    for _, language in ipairs({ "typescript", "javascript" }) do
      dap.configurations[language] = {
        {
          type = "pwa-node",
          request = "attach",
          name = "Attach to Node",
          processId = require("dap.utils").pick_process,
          cwd = vim.fn.getcwd(),
          -- ❌ دیگه port نده. چون adapter خودش executable هست، نه server
        },
      }
    end
  end,
}
