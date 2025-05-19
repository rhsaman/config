return {

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
      { "<leader>h", group = "harpoon" }, -- group
      { "<leader>d", group = "debug" },
      { "<leader>b", group = "buffer" },
      { "<leader>a", group = "avante ai" },
      { "<leader>q", group = "quick fix" },
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
}
