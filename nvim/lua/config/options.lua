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

-- vim.opt.shadafile = vim.fn.stdpath("config") .. "/shada"

-- clipboard
opt.clipboard:append("unnamedplus") -- use system clipboard as default register

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom

-- rust auto save
vim.g.rustfmt_autosave = 1

-- vim.g.python3_host_prog = "/Users/saman/Documents/code/music/ai/.venv/bin/python"

-- Filetype detection for .env files (Comment.nvim needs a filetype)
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	pattern = { ".env", ".env.*", "*.env" },
	callback = function()
		vim.bo.filetype = "sh"
	end,
})

-- fold with treesitter
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldenable = true

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "NvimTree", "neo-tree", "dashboard", "alpha" },
	callback = function()
		vim.opt_local.foldmethod = "manual"
	end,
})

-- persist folds between sessions
-- mkview can't save closed folds with foldmethod=expr (treesitter),
-- so we store the start line of each closed fold ourselves.
local fold_state_dir = vim.fn.stdpath("state") .. "/foldview"
vim.fn.mkdir(fold_state_dir, "p")

local function is_real_file()
	return vim.fn.expand("%") ~= "" and vim.bo.buftype == ""
end

local function fold_state_file()
	return fold_state_dir .. "/" .. vim.fn.sha256(vim.fn.expand("%:p"))
end

local function save_folds()
	if not is_real_file() then
		return
	end
	local closed = {}
	local lnum = 1
	local last = vim.fn.line("$")
	while lnum <= last do
		local fc = vim.fn.foldclosed(lnum)
		if fc ~= -1 then
			closed[#closed + 1] = fc
			lnum = vim.fn.foldclosedend(fc) + 1
		else
			lnum = lnum + 1
		end
	end
	local f = io.open(fold_state_file(), "w")
	if f then
		f:write(table.concat(closed, ","))
		f:close()
	end
end

-- treesitter folds compute lazily, so retry until the parser is ready
local function close_fold_lines(lines, attempt)
	local remaining = {}
	for _, lnum in ipairs(lines) do
		if vim.fn.foldclosed(lnum) == -1 then
			vim.cmd(lnum .. "foldclose")
			if vim.fn.foldclosed(lnum) == -1 then
				remaining[#remaining + 1] = lnum
			end
		end
	end
	if #remaining > 0 and attempt < 5 then
		vim.defer_fn(function()
			close_fold_lines(remaining, attempt + 1)
		end, 200 * attempt)
	end
end

local function restore_folds()
	if not is_real_file() then
		return
	end
	local f = io.open(fold_state_file(), "r")
	if not f then
		return
	end
	local content = f:read("*a") or ""
	f:close()
	if content == "" then
		return
	end
	local buf = vim.api.nvim_get_current_buf()
	local lines = {}
	for _, lnum in ipairs(vim.split(content, ",")) do
		lines[#lines + 1] = tonumber(lnum)
	end
	vim.defer_fn(function()
		if not vim.api.nvim_buf_is_valid(buf) or vim.api.nvim_get_current_buf() ~= buf then
			return
		end
		close_fold_lines(lines, 1)
	end, 100)
end

-- NOTE: no BufWinLeave save here — by the time it fires the folds are
-- already gone, and it would overwrite the good state with an empty one.
-- The fold-key mappings above are the only save point.

vim.api.nvim_create_autocmd({ "BufWinEnter", "BufReadPost" }, {
	callback = function()
		restore_folds()
	end,
})

-- save fold state immediately after any fold key (BufWinLeave is too late:
-- folds are already gone by the time it fires)
for _, key in ipairs({ "za", "zA", "zc", "zC", "zo", "zO", "zm", "zM", "zr", "zR", "zx", "zX" }) do
	vim.keymap.set("n", key, function()
		vim.cmd("normal! " .. key)
		save_folds()
	end, { silent = true, desc = key .. " + save fold state" })
end

-- todo color
vim.api.nvim_set_hl(0, "TodoFg", { fg = "#00FF00" })
