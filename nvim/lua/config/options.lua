local opt = vim.opt -- for conciseness
-- line numbers
opt.relativenumber = false -- show relative line numbers
opt.number = true -- shows absolute line number on cursor line (when relative number is on)

-- tabs & indentation
opt.tabstop = 4 -- 2 spaces for tabs (prettier default)
opt.shiftwidth = 2 -- 2 spaces for indent width
opt.expandtab = true -- expand tab to spaces
opt.autoindent = true -- copy indent from current line when starting new one

-- line wrapping
opt.wrap = false -- disable line wrapping

-- search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- if you include mixed case in your search, assumes you want case-sensitive

-- cursor line
opt.cursorline = false -- highlight the current cursor line

opt.termguicolors = true

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

vim.opt.shadafile = vim.fn.stdpath("config") .. "/shada"

-- clipboard
opt.clipboard:append("unnamedplus") -- use system clipboard as default register

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom

-- rust auto save
vim.g.rustfmt_autosave = 1

-- vim.g.python3_host_prog = "/Users/saman/Documents/code/music/ai/.venv/bin/python"

-- workdir
-- local function setup_project_root()
--   local path = vim.fn.expand("%:p:h")
--   local git_dir = vim.fn.finddir(".git", path .. ";")
--   if git_dir ~= "" then
--     local root = vim.fn.fnamemodify(git_dir, ":h")
--     vim.cmd("cd " .. root)
--   else
--     vim.o.autochdir = true
--     print("Git not found: autochdir enabled")
--   end
-- end
-- setup_project_root()

-- fold
vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function()
		-- List of file types where foldmethod should not be set
		local exclude_filetypes = { "NvimTree", "neo-tree", "dashboard", "alpha" }
		if not vim.tbl_contains(exclude_filetypes, vim.bo.filetype) then
			-- Set foldmethod to 'indent' only for non-explorer files
			opt.foldmethod = "indent"
			opt.foldlevel = 99 -- Optional: keeps folds open by default
			-- opt.foldenable = true
		end
	end,
})

-- todo color
vim.api.nvim_set_hl(0, "TodoFg", { fg = "#00FF00" })
