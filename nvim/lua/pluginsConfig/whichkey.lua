return {

  "folke/which-key.nvim",
  lazy = true,
  event = "VeryLazy",
  opts = {
    icons = {
      breadcrumb = "»",
      separator = "➜",
      group = "◆",
    },
    notify = true,
    delay = 0,
    win = {
      border = "rounded",
      title = " WhichKey ",
      title_pos = "center",
    },
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
      { "<leader>a", group = "ai" },
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
