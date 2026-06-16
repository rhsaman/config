return {
  "tpope/vim-fugitive",
  cmd = { "Git", "Gdiffsplit", "Gvdiffsplit", "Gread", "Gwrite", "Ggrep", "GMove", "GDelete", "GRename" },
  keys = {
    { "<leader>ga", ":Git add .<cr>", desc = "Git add",  silent = true },
    { "<leader>gi", "<cmd>:Git<cr>",  desc = "fugitive", silent = true },
  },
}
