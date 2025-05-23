vim.g.mapleader = " "

local keymap = vim.keymap

-- nohls
keymap.set("n", "<Esc>", "<cmd>nohls<cr>", { desc = "nohls" })

-- autoSession
keymap.set("n", "<leader>wr", ":SessionRestore<CR>", { desc = "Restore session for cwd" })             -- restore last workspace session for current directory
keymap.set("n", "<leader>ws", ":SessionSave<CR>", { desc = "Save session for auto session root dir" }) -- save workspace session for current working directory

-- lsp
keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "See available code actions" })     -- see available code actions, in visual mode will apply to selection
keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", { desc = "Show LSP type definitions" }) -- show lsp type definitions
keymap.set("n", "gr", "<cmd>Telescope lsp_references<CR>", { desc = "Show LSP references" })        -- show definition, references
-- keymap.set("n", "R", vim.lsp.buf.hover, { desc = "Show documentation for what is under cursor" }) -- show documentation for what is under cursor
keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })                      -- go to declaration
keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })                -- go to declaration

------------------------resize window-----------------------

keymap.set("n", "<C-w>l", "<C-w>10<", { desc = "Resize window left" })
keymap.set("n", "<C-w>h", "<C-w>10>", { desc = "Resize window right" })
keymap.set("n", "<C-w>j", "<C-w>10-", { desc = "Resize window up" })
keymap.set("n", "<C-w>k", "<C-w>10+", { desc = "Resize window down" })
-----------------------tabs-----------------------
-- keymap.set("n", "<leader>To", ":tabnew<CR>", { desc = "open tab" })
-- keymap.set("n", "<leader>Tx", ":tabclose<CR>", { desc = "close tab" })
-- keymap.set("n", "<leader>Tk", ":tabn<CR>", { desc = "next tab" })
-- keymap.set("n", "<leader>Tj", ":tabp<CR>", { desc = "previous tab" })

-- telescope git commands (not on youtube nvim video)
keymap.set(
  "n",
  "<leader>gsc",
  "<cmd>Telescope git_commits<cr>",
  { desc = "list all git commits (use <cr> to checkout)" }
)
keymap.set(
  "n",
  "<leader>gsC",
  "<cmd>Telescope git_bcommits<cr>",
  { desc = "list git commits for current file/buffer (use <cr> to checkout)" }
)
keymap.set("n", "<leader>gsb", "<cmd>Telescope git_branches<cr>", { desc = "list git branches (use <cr> to checkout)" })
keymap.set(
  "n",
  "<leader>gss",
  "<cmd>Telescope git_status<cr>",
  { desc = "list current changes per file with diff preview" }
)

-- harpoon
keymap.set("n", "<leader>ha", ":lua require('harpoon.mark').add_file()<cr>", { desc = "harpoon add file" })
keymap.set("n", "<leader>ho", ":lua require('harpoon.ui').toggle_quick_menu()<cr>", { desc = "harpoon files" })
-- keymap.set("n", "<C-n>", ':lua require("harpoon.ui").nav_next()<cr>', { desc = "harpoon next file" })
-- keymap.set("n", "<C-p>", ':lua require("harpoon.ui").nav_prev()<cr>', { desc = "harpoon previous files" })

-- maximizer
keymap.set("n", "<leader>m", ":MaximizerToggle<Cr>", { desc = "maximizer" })

-- quick fix
keymap.set("n", "<leader>qn", ":cnext<Cr>", { desc = "next quickfix" })
keymap.set("n", "<leader>qp", ":cprevious<Cr>", { desc = "next quickfix" })

-- bufferline
keymap.set("n", "<C-n>", ":BufferLineCycleNext<cr>", { desc = "next buffer" })
keymap.set("n", "<C-p>", ":BufferLineCyclePrev<cr>", { desc = "prev buffer" })
keymap.set("n", "<leader>bn", ":BufferLineMoveNext<cr>", { desc = "move next buffer" })
keymap.set("n", "<leader>bp", ":BufferLineMovePrev<cr>", { desc = "move prev buffer" })
keymap.set("n", "<leader>bd", ":bd!<CR>", { desc = "close buffer" })
keymap.set("n", "<leader>bl", ":BufferLineCloseRight<CR>", { desc = "close right buffer" })
keymap.set("n", "<leader>bh", ":BufferLineCloseLeft<CR>", { desc = "close left buffer" })
keymap.set("n", "<leader>bg", ":BufferLinePick<cr>", { desc = "go to buffer" })
keymap.set("n", "<leader>bs", ":BufferLineSortByDirectory<cr>", { desc = "sort buffer with dir" })
keymap.set("n", "<leader>bt", ":BufferLineTogglePin<cr>", { desc = "toggle buffer pin" })

-- Close all buffers except current and zsh terminal
vim.keymap.set("n", "<leader>bo", function()
  local current = vim.api.nvim_get_current_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= current and vim.api.nvim_buf_is_loaded(buf) then
      local bufname = vim.fn.bufname(buf)
      local buftype = vim.bo[buf].buftype

      -- Prevent closing terminal buffers that run zsh
      if buftype ~= "terminal" or not string.find(bufname, "zsh") then
        vim.cmd("bd! " .. buf)
      end
    end
  end
end, { desc = "Close all buffers except current and zsh terminal" })

vim.keymap.set("n", "<leader>i", function()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.lsp.inlay_hint then
    local ok, enabled = pcall(vim.lsp.inlay_hint.is_enabled, bufnr)
    if ok then
      vim.lsp.inlay_hint.enable(bufnr, not enabled)
    else
      vim.notify("Inlay hints not available", vim.log.levels.WARN)
    end
  end
end, { desc = "Toggle inlay hints" })
