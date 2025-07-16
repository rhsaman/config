vim.g.mapleader = " "

local keymap = vim.keymap

-- nohls
keymap.set("n", "<Esc>", "<cmd>nohls<cr>", { desc = "nohls" })

-- autoSession
keymap.set("n", "<leader>wr", ":SessionRestore<CR>", { desc = "Restore session for cwd" }) -- restore last workspace session for current directory
keymap.set("n", "<leader>ws", ":SessionSave<CR>", { desc = "Save session for auto session root dir" }) -- save workspace session for current working directory

-- lsp

-- inlay_hint
vim.keymap.set("n", "<leader>i", function()
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "Toggle inlay hints" })

keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "See available code actions" }) -- see available code actions, in visual mode will apply to selection
keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", { desc = "Show LSP type definitions" }) -- show lsp type definitions
keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" }) -- go to declaration
keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, { desc = "Show signature help" })
keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, { desc = "Show signature help" })

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
keymap.set("n", "<leader>hn", ':lua require("harpoon.ui").nav_next()<cr>', { desc = "harpoon next file" })
keymap.set("n", "<leader>hp", ':lua require("harpoon.ui").nav_prev()<cr>', { desc = "harpoon previous files" })
