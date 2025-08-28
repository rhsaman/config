vim.g.mapleader = " "

local keymap = vim.keymap

-- nohls
keymap.set("n", "<Esc>", "<cmd>nohls<cr>", { desc = "nohls" })

-- autoSession
keymap.set("n", "<leader>wr", ":SessionRestore<CR>", { desc = "Restore session for cwd" })             -- restore last workspace session for current directory
keymap.set("n", "<leader>ws", ":SessionSave<CR>", { desc = "Save session for auto session root dir" }) -- save workspace session for current working directory

-- lsp

-- inlay_hint
vim.keymap.set("n", "<leader>i", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "Toggle inlay hints" })

keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "See available code actions" })     -- see available code actions, in visual mode will apply to selection
keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", { desc = "Show LSP type definitions" }) -- show lsp type definitions
keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })                -- go to declaration
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
keymap.set("n", "<C-n>", ':lua require("harpoon.ui").nav_next()<cr>', { desc = "harpoon next file" })
keymap.set("n", "<C-p>", ':lua require("harpoon.ui").nav_prev()<cr>', { desc = "harpoon previous files" })

local ollama_chat = require("config.ollama_chat")

-- Visual mode - Send selection to Ollama (floating window)
vim.api.nvim_set_keymap(
  "v",
  "<leader>os",
  ':<C-U>lua require("config.ollama_chat").send_to_ollama()<CR>',
  { noremap = true, silent = true, desc = "Send selection to Ollama (floating)" }
)

-- Normal mode - Send current line to Ollama (floating window)
vim.api.nvim_set_keymap(
  "n",
  "<leader>os",
  ':lua require("config.ollama_chat").send_to_ollama()<CR>',
  { noremap = true, silent = true, desc = "Send current line to Ollama (floating)" }
)

-- Visual mode - Send selection to chat window with Ctrl+S
vim.api.nvim_set_keymap(
  "v",
  "<C-s>",
  ':<C-U>lua require("config.ollama_chat").send_selection_to_chat()<CR>',
  { noremap = true, silent = true, desc = "Send selection to Ollama chat" }
)

-- Normal mode - Send current line to chat window with Ctrl+S
vim.api.nvim_set_keymap(
  "n",
  "<C-s>",
  ':lua require("config.ollama_chat").send_selection_to_chat()<CR>',
  { noremap = true, silent = true, desc = "Send current line to Ollama chat" }
)

-- Toggle chat window
vim.api.nvim_set_keymap(
  "n",
  "<leader>oc",
  ':lua require("config.ollama_chat").toggle_chat_window()<CR>',
  { noremap = true, silent = true, desc = "Toggle Ollama Chat Window" }
)

-- Debug test - simple ollama call
vim.api.nvim_set_keymap(
  "n",
  "<leader>ot",
  ':lua require("config.ollama_chat").test_ollama()<CR>',
  { noremap = true, silent = true, desc = "Test Ollama Connection" }
)

-- Navigate to chat input window
vim.api.nvim_set_keymap(
  "n",
  "<leader>oi",
  ':lua require("config.ollama_chat").focus_chat_input()<CR>',
  { noremap = true, silent = true, desc = "Focus Ollama Chat Input" }
)

-- Navigate to chat history window
vim.api.nvim_set_keymap(
  "n",
  "<leader>oh",
  ':lua require("config.ollama_chat").focus_chat_history()<CR>',
  { noremap = true, silent = true, desc = "Focus Ollama Chat History" }
)

-- Debug selection capture (temporary)
vim.api.nvim_set_keymap(
  "v",
  "<leader>od",
  ':<C-U>lua require("config.ollama_chat").debug_selection()<CR>',
  { noremap = true, silent = false, desc = "Debug selection capture" }
)
vim.api.nvim_set_keymap(
  "n",
  "<leader>od",
  ':lua require("config.ollama_chat").debug_selection()<CR>',
  { noremap = true, silent = false, desc = "Debug selection capture" }
)
