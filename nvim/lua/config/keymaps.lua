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
keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { desc = "Go to LSP definition", silent = true }) -- show lsp type definitions (more efficient than Telescope)
keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", { desc = "Go to implementation", silent = true }) -- go to declaration
keymap.set("n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", { desc = "Show signature help", silent = true })
keymap.set("i", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", { desc = "Show signature help", silent = true })

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
keymap.set("n", "<C-n>", ':lua require("harpoon.ui").nav_next()<cr>', { desc = "harpoon next file" })
keymap.set("n", "<C-p>", ':lua require("harpoon.ui").nav_prev()<cr>', { desc = "harpoon previous files" })

-- telescope - lazy load on keypress
keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "find files", silent = true })
keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", { desc = "search string", silent = true })
keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "recent files", silent = true })
keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "buffers", silent = true })
keymap.set("n", "<leader>fd", "<cmd>lua vim.diagnostic.open_float()<CR>", { desc = "diagnostics", silent = true })
keymap.set("n", "<leader>fl", "<cmd>Telescope lsp_document_symbols<cr>", { desc = "list symbols", silent = true })

-- toggle rtl
keymap.set("n", "<leadel>l", function()
	vim.o.rightleft = not vim.o.rightleft
end, { desc = "Toggle right-to-left mode" })
