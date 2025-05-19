return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = "nvim-tree/nvim-web-devicons",
  config = function()
    require("bufferline").setup({
      options = {
        mode = "buffers", -- set to "tabs" to only show tabpages instead
        custom_filter = function(buf_number)
          local buf_name = vim.fn.bufname(buf_number)
          local buf_type = vim.bo[buf_number].buftype

          -- Hide terminal buffers that run zsh
          if buf_type == "terminal" and buf_name:find("zsh") then
            return false
          end

          return true
        end,
        groups = {
          items = {
            require("bufferline.groups").builtin.pinned:with({ icon = "󰐃 " }),
          },
        },

        hover = {
          enabled = true,
          delay = 200,
          reveal = { "close" },
        },

        indicator = {
          icon = "🔥 ", -- this should be omitted if indicator style is not 'icon'
          style = "icon", --"icon" | "underline" | "none",
        },

        numbers = "ordinal",
      },
    })
  end,
}
