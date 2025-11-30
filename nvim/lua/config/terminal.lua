local term_opts = { silent = true }
vim.keymap.set("t", "<esc><esc>", "<c-\\><c-n>", term_opts)

local state = {
	floating = {
		buf = -1,
		win = -1,
	},
}

local function create_floating_window(opts)
	opts = opts or {}
	local width = opts.width or math.floor(vim.o.columns * 0.8)
	local height = opts.height or math.floor(vim.o.lines * 0.5)
	local col = math.floor((vim.o.columns - width) / 2)
	local row = math.floor((vim.o.lines - height) / 2)

	local buf = nil
	if vim.api.nvim_buf_is_valid(opts.buf) then
		buf = opts.buf
	else
		buf = vim.api.nvim_create_buf(false, true) -- scratch buffer
	end

	local win_config = {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = "rounded",
	}

	local win = vim.api.nvim_open_win(buf, true, win_config)
	return { buf = buf, win = win }
end

local function toggle_terminal()
	if not vim.api.nvim_win_is_valid(state.floating.win) then
		-- مسیر فایل فعلی را ست کن قبل از ساخت buffer
		local file_dir = vim.fn.expand("%:p:h")
		vim.cmd("lcd " .. file_dir)

		state.floating = create_floating_window({ buf = state.floating.buf })

		-- اگر buffer ترمینال نیست، ترمینال بساز
		if vim.bo[state.floating.buf].buftype ~= "terminal" then
			vim.api.nvim_command("terminal")
		end

		vim.cmd("startinsert")
	else
		vim.api.nvim_win_hide(state.floating.win)
	end
end

local function close_terminal()
	if vim.api.nvim_win_is_valid(state.floating.win) then
		vim.api.nvim_win_hide(state.floating.win)
	end
end

vim.keymap.set("n", "<leader>j", toggle_terminal, { desc = "terminal toggle" })
vim.keymap.set("n", "<C-q>", close_terminal, { noremap = true, desc = "Close terminal in normal mode" })

vim.keymap.set("t", "<C-q>", function()
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), "n", false)
	close_terminal()
end, { noremap = true, desc = "Exit terminal and close on q" })

vim.api.nvim_set_keymap("t", "<C-n>", [[<C-\><C-n>]], { noremap = true })
