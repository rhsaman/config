local M = {}

-- Chat window state
local chat_win = nil
local chat_buf = nil
local input_buf = nil
local input_win = nil
local chat_history = {}
local current_job = nil -- Track current ollama job

-- Code edit state
local pending_edit = {
	original_buf = nil,
	original_start_line = nil,
	original_end_line = nil,
	original_start_col = nil,
	original_end_col = nil,
	suggested_code = nil,
	response_id = nil,
}

-- Extract code from response (supports code blocks and inline code)
function M.extract_code_from_response(response)
	if not response or response == "" then
		return nil
	end

	-- First try to find code blocks (```code```)
	local code_block = response:match("```[^\n]*\n(.-)```")
	if code_block then
		return code_block:gsub("^%s*", ""):gsub("%s*$", "")
	end

	-- Try to find inline code (`code`)
	local inline_code = response:match("`([^`]+)`")
	if inline_code then
		return inline_code
	end

	-- If it looks like pure code (contains common programming patterns)
	if
		response:match("function")
		or response:match("class")
		or response:match("{.-}")
		or response:match("import")
		or response:match("require")
		or response:match("local.*=")
		or response:match("def ")
		or response:match("var ")
		or response:match("const ")
		or response:match("let ")
	then
		return response:gsub("^%s*", ""):gsub("%s*$", "")
	end

	return nil
end

-- Check if response contains code that could be applied as an edit
function M.is_code_edit_response(response)
	return M.extract_code_from_response(response) ~= nil
end

-- Store the current selection context for later editing
function M.store_selection_context()
	local buf = vim.api.nvim_get_current_buf()
	local vstart = vim.fn.getpos("'<")
	local vend = vim.fn.getpos(">")

	-- Check if we have a valid visual selection
	if vstart[2] > 0 and vend[2] > 0 and (vstart[2] ~= vend[2] or vstart[3] ~= vend[3]) then
		-- We have a valid visual selection
		pending_edit.original_buf = buf
		pending_edit.original_start_line = vstart[2]
		pending_edit.original_end_line = vend[2]
		pending_edit.original_start_col = vstart[3]
		pending_edit.original_end_col = vend[3]

		print("Debug: Stored visual selection from line " .. vstart[2] .. " to " .. vend[2])
	else
		-- No visual selection, use current line
		local current_line = vim.api.nvim_win_get_cursor(0)[1]
		local line_text = vim.api.nvim_get_current_line()

		pending_edit.original_buf = buf
		pending_edit.original_start_line = current_line
		pending_edit.original_end_line = current_line
		pending_edit.original_start_col = 1
		pending_edit.original_end_col = #line_text

		print("Debug: Stored current line " .. current_line .. " (no visual selection)")
	end

	return buf, vstart, vend
end

-- گرفتن متن انتخابی یا خط جاری
function M.get_selection()
	-- First try to get visual selection if we were just in visual mode
	local vstart = vim.fn.getpos("'<")
	local vend = vim.fn.getpos("'>")

	-- Check if we have a valid visual selection
	if vstart[2] > 0 and vend[2] > 0 and (vstart[2] ~= vend[2] or vstart[3] ~= vend[3]) then
		local lines = vim.fn.getline(vstart[2], vend[2])
		if #lines == 1 then
			-- Single line selection
			lines[1] = string.sub(lines[1], vstart[3], vend[3])
		else
			-- Multi-line selection
			lines[1] = string.sub(lines[1], vstart[3])
			lines[#lines] = string.sub(lines[#lines], 1, vend[3])
		end
		return table.concat(lines, "\n")
	else
		-- No selection, get current line
		return vim.fn.getline(".")
	end
end

-- اجرای Ollama async (truly async using jobstart)
function M.query_ollama_async(text, callback)
	-- Stop current job if running
	if current_job and vim.fn.jobstop then
		vim.fn.jobstop(current_job)
		current_job = nil
	end

	-- Clean and prepare text
	local clean_text = text:gsub('"', '\\"'):gsub("\n", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")

	if clean_text == "" then
		callback("Error: Empty text provided")
		return
	end

	-- Create a temporary file to pass text to ollama (to avoid shell escaping issues)
	local temp_file = vim.fn.tempname()
	vim.fn.writefile({ clean_text }, temp_file)

	local cmd =
		{ "sh", "-c", string.format('cat "%s" | ollama run qwen3:4b-instruct-2507-q4_K_M 2>/dev/null', temp_file) }

	local response_lines = {}
	local callback_called = false

	current_job = vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if data and #data > 0 then
				for _, line in ipairs(data) do
					if line and line ~= "" then
						-- Clean escape codes but keep most content
						local clean_line = line
							:gsub("\27%[%d*;*%d*[mK]", "") -- Remove ANSI escape codes
							:gsub("%[%?25[lh]", "") -- Remove cursor visibility codes
							:gsub("\r", "") -- Remove carriage returns

						-- Only filter out ollama stats, keep everything else
						if
							not clean_line:match("^total duration:")
							and not clean_line:match("^load duration:")
							and not clean_line:match("^prompt eval")
							and not clean_line:match("^eval count:")
							and not clean_line:match("^eval duration:")
							and not clean_line:match("^eval rate:")
						then
							table.insert(response_lines, clean_line)
						end
					end
				end
			end
		end,
		on_stderr = function(_, err)
			-- Silently handle errors
		end,
		on_exit = function(_, exit_code)
			-- Clean up temp file
			vim.fn.delete(temp_file)

			if not callback_called then
				callback_called = true

				if exit_code == 0 then
					if #response_lines > 0 then
						local final_response = table.concat(response_lines, "\n")
						-- Clean up excessive whitespace but preserve structure
						final_response = final_response:gsub("\n\n\n+", "\n\n"):gsub("^%s*", ""):gsub("%s*$", "")

						-- Limit response length if too long
						if #final_response > 2000 then
							final_response = final_response:sub(1, 2000) .. "\n\n[Response truncated - too long]"
						end

						callback(final_response)
					else
						callback("No response from Ollama")
					end
				else
					callback("Command failed with exit code: " .. exit_code)
				end
			end
		end,
	})
end

-- نمایش پاسخ در floating window
function M.show_response(response)
	local buf = vim.api.nvim_create_buf(false, true)
	local width = math.floor(vim.o.columns * 0.6)
	local height = math.floor(vim.o.lines * 0.4)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	})

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(response, "\n"))
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

-- Apply code edit to original buffer (without switching to it)
function M.accept_code_edit()
	if
		not pending_edit.original_buf
		or not pending_edit.suggested_code
		or not vim.api.nvim_buf_is_valid(pending_edit.original_buf)
	then
		print("No pending code edit to accept")
		return
	end

	-- Remember current window to return to it later
	local current_win = vim.api.nvim_get_current_win()

	-- Debug: print ALL pending edit info
	print("Debug: Raw pending_edit values:")
	print("  original_start_line: " .. tostring(pending_edit.original_start_line))
	print("  original_end_line: " .. tostring(pending_edit.original_end_line))
	print("  original_start_col: " .. tostring(pending_edit.original_start_col))
	print("  original_end_col: " .. tostring(pending_edit.original_end_col))

	-- Get buffer info for validation
	local buf_line_count = vim.api.nvim_buf_line_count(pending_edit.original_buf)
	print("  buffer line count: " .. buf_line_count)

	-- Apply the edit to the original buffer (without switching view)
	local code_lines = vim.split(pending_edit.suggested_code, "\n")

	-- Ensure we have valid line numbers and validate them
	local start_line = pending_edit.original_start_line or 1
	local end_line = pending_edit.original_end_line or start_line
	local start_col = pending_edit.original_start_col or 1
	local end_col = pending_edit.original_end_col or 1

	-- Clamp values to valid ranges
	start_line = math.max(1, math.min(start_line, buf_line_count))
	end_line = math.max(1, math.min(end_line, buf_line_count))

	-- Ensure start <= end
	if start_line > end_line then
		start_line, end_line = end_line, start_line
	end

	print("Debug: Validated values:")
	print("  start_line: " .. start_line .. ", end_line: " .. end_line)
	print("  start_col: " .. start_col .. ", end_col: " .. end_col)

	-- Calculate 0-based indices for nvim_buf_set_lines
	local zero_start = start_line - 1 -- 0-based start
	local zero_end = start_line -- exclusive end (1-based)

	if start_line ~= end_line then
		-- Multi-line case: end should be the line AFTER the last line to replace
		zero_end = end_line
	end

	print("Debug: nvim_buf_set_lines params: " .. zero_start .. ", " .. zero_end)

	-- Validate the indices before calling nvim_buf_set_lines
	if zero_start < 0 or zero_start > buf_line_count or zero_end < zero_start or zero_end > buf_line_count then
		print(
			"Error: Invalid line indices. start="
				.. zero_start
				.. ", end="
				.. zero_end
				.. ", buf_lines="
				.. buf_line_count
		)
		return
	end

	-- Replace the selection with the new code
	if start_line == end_line then
		-- Single line replacement, but the suggested code might be multi-line
		local line = vim.api.nvim_buf_get_lines(pending_edit.original_buf, zero_start, zero_end, false)[1] or ""
		local prefix = line:sub(1, start_col - 1)
		local suffix = line:sub(end_col + 1)

		if #code_lines == 1 then
			-- Single line suggested code - simple replacement
			local new_line = prefix .. code_lines[1] .. suffix
			vim.api.nvim_buf_set_lines(pending_edit.original_buf, zero_start, zero_end, false, { new_line })
		else
			-- Multi-line suggested code replacing a single line selection
			local new_lines = {}
			-- First line: prefix + first line of code
			table.insert(new_lines, prefix .. code_lines[1])
			-- Middle lines: just the code lines
			for i = 2, #code_lines - 1 do
				table.insert(new_lines, code_lines[i])
			end
			-- Last line: last line of code + suffix
			table.insert(new_lines, code_lines[#code_lines] .. suffix)

			vim.api.nvim_buf_set_lines(pending_edit.original_buf, zero_start, zero_end, false, new_lines)
		end
	else
		-- Multi-line replacement
		vim.api.nvim_buf_set_lines(pending_edit.original_buf, zero_start, zero_end, false, code_lines)
	end

	-- Clear pending edit
	pending_edit = {
		original_buf = nil,
		original_start_line = nil,
		original_end_line = nil,
		original_start_col = nil,
		original_end_col = nil,
		suggested_code = nil,
		response_id = nil,
	}

	-- Remove accept/deny options from chat
	M.clear_edit_options()

	-- Stay in current window (don't switch to original buffer)
	if vim.api.nvim_win_is_valid(current_win) then
		vim.api.nvim_set_current_win(current_win)
	end

	-- Focus back to input window if we're in chat mode
	if input_win and vim.api.nvim_win_is_valid(input_win) then
		vim.api.nvim_set_current_win(input_win)
		vim.cmd("startinsert")
	end

	print("Code edit applied successfully! (Original file updated in background)")
end

-- Deny code edit
function M.deny_code_edit()
	-- Clear pending edit
	pending_edit = {
		original_buf = nil,
		original_start_line = nil,
		original_end_line = nil,
		original_start_col = nil,
		original_end_col = nil,
		suggested_code = nil,
		response_id = nil,
	}

	-- Remove accept/deny options from chat
	M.clear_edit_options()

	print("Code edit rejected.")
end

-- Clear edit options from chat window
function M.clear_edit_options()
	if chat_buf and vim.api.nvim_buf_is_valid(chat_buf) then
		vim.api.nvim_buf_set_option(chat_buf, "modifiable", true)
		local lines = vim.api.nvim_buf_get_lines(chat_buf, 0, -1, false)

		-- Find and remove accept/deny lines
		local new_lines = {}
		for _, line in ipairs(lines) do
			if not line:match("^%[ACCEPT%]") and not line:match("^%[DENY%]") and not line:match("^>>> Press") then
				table.insert(new_lines, line)
			end
		end

		vim.api.nvim_buf_set_lines(chat_buf, 0, -1, false, new_lines)
		vim.api.nvim_buf_set_option(chat_buf, "modifiable", false)
	end
end

-- Add accept/deny options to chat
function M.add_edit_options()
	if chat_buf and vim.api.nvim_buf_is_valid(chat_buf) then
		vim.api.nvim_buf_set_option(chat_buf, "modifiable", true)
		local options = {
			"",
			">>> Press 'a' to ACCEPT this code edit or 'd' to DENY it <<<",
			"[ACCEPT] - Apply the suggested code to your original selection",
			"[DENY] - Reject the code edit",
			"",
		}
		vim.api.nvim_buf_set_lines(chat_buf, -1, -1, false, options)
		vim.api.nvim_buf_set_option(chat_buf, "modifiable", false)

		-- Auto scroll to bottom
		if chat_win and vim.api.nvim_win_is_valid(chat_win) then
			local line_count = vim.api.nvim_buf_line_count(chat_buf)
			vim.api.nvim_win_set_cursor(chat_win, { line_count, 0 })
		end
	end
end

-- Add message to chat history and display
function M.add_to_chat(message, is_user)
	local timestamp = os.date("%H:%M")
	local prefix = is_user and "[" .. timestamp .. "] You: " or "[" .. timestamp .. "] AI: "
	local formatted_message = prefix .. message

	table.insert(chat_history, formatted_message)

	if chat_buf and vim.api.nvim_buf_is_valid(chat_buf) then
		vim.api.nvim_buf_set_option(chat_buf, "modifiable", true)
		vim.api.nvim_buf_set_lines(chat_buf, -1, -1, false, vim.split(formatted_message, "\n"))
		vim.api.nvim_buf_set_lines(chat_buf, -1, -1, false, { "" })
		vim.api.nvim_buf_set_option(chat_buf, "modifiable", false)

		-- Auto scroll to bottom
		if chat_win and vim.api.nvim_win_is_valid(chat_win) then
			local line_count = vim.api.nvim_buf_line_count(chat_buf)
			vim.api.nvim_win_set_cursor(chat_win, { line_count, 0 })
		end
	end
end

-- Create or show chat window as resizable panes
function M.toggle_chat_window()
	-- Check if chat windows exist and are valid
	local chat_exists = chat_win and vim.api.nvim_win_is_valid(chat_win)
	local input_exists = input_win and vim.api.nvim_win_is_valid(input_win)

	if chat_exists or input_exists then
		-- Close chat windows
		if chat_exists then
			vim.api.nvim_win_close(chat_win, true)
		end
		if input_exists then
			vim.api.nvim_win_close(input_win, true)
		end
		chat_win = nil
		input_win = nil
		return
	end

	-- Create chat buffer if it doesn't exist
	if not chat_buf or not vim.api.nvim_buf_is_valid(chat_buf) then
		chat_buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_option(chat_buf, "buftype", "nofile")
		vim.api.nvim_buf_set_option(chat_buf, "swapfile", false)
		vim.api.nvim_buf_set_option(chat_buf, "filetype", "markdown")
		vim.api.nvim_buf_set_name(chat_buf, "[Ollama Chat]")

		-- Add welcome message
		local welcome = "=== Ollama Chat ==="
		vim.api.nvim_buf_set_lines(chat_buf, 0, -1, false, { welcome, "" })
		vim.api.nvim_buf_set_option(chat_buf, "modifiable", false)
	end

	-- Create input buffer if it doesn't exist
	if not input_buf or not vim.api.nvim_buf_is_valid(input_buf) then
		input_buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_option(input_buf, "buftype", "nofile")
		vim.api.nvim_buf_set_option(input_buf, "swapfile", false)
		vim.api.nvim_buf_set_option(input_buf, "filetype", "text")
		vim.api.nvim_buf_set_name(input_buf, "[Ollama Input]")
	end

	-- Create vertical split on the right (40% width)
	vim.cmd("rightbelow 40vnew")
	chat_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(chat_win, chat_buf)

	-- Create horizontal split in chat pane for input (larger height)
	vim.cmd("rightbelow 8split")
	input_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(input_win, input_buf)

	-- Set up input buffer keymaps
	vim.api.nvim_buf_set_keymap(
		input_buf,
		"n",
		"<Esc>",
		":lua require('config.ollama_chat').toggle_chat_window()<CR>",
		{ noremap = true, silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		input_buf,
		"i",
		"<C-CR>",
		"<Esc>:lua require('config.ollama_chat').send_chat_message()<CR>",
		{ noremap = true, silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		input_buf,
		"n",
		"<CR>",
		":lua require('config.ollama_chat').send_chat_message()<CR>",
		{ noremap = true, silent = true }
	)

	-- Set up chat buffer keymaps
	vim.api.nvim_buf_set_keymap(
		chat_buf,
		"n",
		"<Esc>",
		":lua require('config.ollama_chat').toggle_chat_window()<CR>",
		{ noremap = true, silent = true }
	)

	-- Add accept/deny keybindings for chat buffer
	vim.api.nvim_buf_set_keymap(
		chat_buf,
		"n",
		"a",
		":lua require('config.ollama_chat').accept_code_edit()<CR>",
		{ noremap = true, silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		chat_buf,
		"n",
		"d",
		":lua require('config.ollama_chat').deny_code_edit()<CR>",
		{ noremap = true, silent = true }
	)

	-- Enter insert mode in input window
	vim.cmd("startinsert")
end

-- Send message from input buffer
function M.send_chat_message()
	if not input_buf or not vim.api.nvim_buf_is_valid(input_buf) then
		print("Error: Input buffer not valid")
		return
	end

	local lines = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
	local message = table.concat(lines, "\n"):gsub("^%s*", ""):gsub("%s*$", "")

	if message == "" then
		return
	end

	-- Clear input buffer
	vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, { "" })

	-- Add user message to chat
	M.add_to_chat(message, true)

	-- Show "thinking" indicator
	M.add_to_chat("Thinking...", false)

	-- Send to Ollama
	M.query_ollama_async(message, function(response)
		vim.schedule(function()
			-- Remove "thinking" indicator
			if chat_buf and vim.api.nvim_buf_is_valid(chat_buf) then
				vim.api.nvim_buf_set_option(chat_buf, "modifiable", true)
				local line_count = vim.api.nvim_buf_line_count(chat_buf)
				-- Remove last 2 lines ("Thinking..." and empty line)
				if line_count >= 2 then
					vim.api.nvim_buf_set_lines(chat_buf, line_count - 2, line_count, false, {})
				end
				vim.api.nvim_buf_set_option(chat_buf, "modifiable", false)
			end

			-- Add AI response
			if response and response ~= "" then
				M.add_to_chat(response, false)

				-- Check if we have a pending edit context and if response contains code
				if pending_edit.original_buf and vim.api.nvim_buf_is_valid(pending_edit.original_buf) then
					local suggested_code = M.extract_code_from_response(response)
					if suggested_code then
						-- Store the suggested code for potential application
						pending_edit.suggested_code = suggested_code
						pending_edit.response_id = os.time() .. "_" .. math.random(1000)

						-- Show accept/deny options
						M.add_edit_options()

						-- Don't focus back to input, let user see accept/deny options
						return
					end
				end
			else
				M.add_to_chat("No response received from Ollama", false)
			end

			-- Focus back to input window (only if no accept/deny options shown)
			if input_win and vim.api.nvim_win_is_valid(input_win) then
				vim.api.nvim_set_current_win(input_win)
				vim.cmd("startinsert")
			end
		end)
	end)
end

-- Get LSP diagnostics for current buffer and selection range
function M.get_lsp_diagnostics_for_selection()
	local buf = vim.api.nvim_get_current_buf()

	-- For current line selection (when no visual selection)
	local current_line = vim.api.nvim_win_get_cursor(0)[1]
	local start_line = current_line
	local end_line = current_line

	-- Try to get visual selection marks
	local vstart = vim.fn.getpos("'<")
	local vend = vim.fn.getpos(">")

	-- If we have a valid visual selection, use it
	if vstart[2] > 0 and vend[2] > 0 and (vstart[2] ~= vend[2] or vstart[3] ~= vend[3]) then
		start_line = vstart[2]
		end_line = vend[2]
	end

	print("Debug: LSP diagnostics range - lines " .. start_line .. " to " .. end_line)

	-- Get all diagnostics for the current buffer
	local diagnostics = vim.diagnostic.get(buf)

	print("Debug: Total diagnostics in buffer: " .. #diagnostics)

	local relevant_diagnostics = {}
	local similar_diagnostics = {} -- Track similar issues throughout the file

	-- Filter diagnostics that are within the selection range
	for _, diag in ipairs(diagnostics) do
		local diag_line = diag.lnum + 1 -- LSP uses 0-based, Vim uses 1-based

		if diag_line >= start_line and diag_line <= end_line then
			table.insert(relevant_diagnostics, diag)
		end

		-- Also collect similar diagnostics (same message pattern) from the whole file
		if diag.message:match("Deprecated") or diag.message:match("nvim_buf_set_option") then
			table.insert(similar_diagnostics, diag)
		end
	end

	print("Debug: Found " .. #relevant_diagnostics .. " diagnostics in selection")
	print("Debug: Found " .. #similar_diagnostics .. " similar diagnostics in entire file")

	-- If we only found a few diagnostics in the selection, but there are many similar ones,
	-- include some of the similar ones to give better context
	if #relevant_diagnostics < 3 and #similar_diagnostics > #relevant_diagnostics then
		print("Debug: Adding similar diagnostics for better context")
		for _, diag in ipairs(similar_diagnostics) do
			local already_included = false
			for _, existing in ipairs(relevant_diagnostics) do
				if diag.lnum == existing.lnum then
					already_included = true
					break
				end
			end
			if not already_included then
				table.insert(relevant_diagnostics, diag)
				-- Limit to avoid too much output
				if #relevant_diagnostics >= 10 then
					break
				end
			end
		end
	end

	return relevant_diagnostics
end

-- Format LSP diagnostics into readable text
function M.format_lsp_diagnostics(diagnostics)
	if #diagnostics == 0 then
		return nil
	end

	local formatted = { "\n\nLSP ERRORS/WARNINGS in this code:" }

	for _, diag in ipairs(diagnostics) do
		local severity = ""
		if diag.severity == 1 then
			severity = "ERROR"
		elseif diag.severity == 2 then
			severity = "WARNING"
		elseif diag.severity == 3 then
			severity = "INFO"
		elseif diag.severity == 4 then
			severity = "HINT"
		end

		local line_info = string.format("Line %d: [%s] %s", diag.lnum + 1, severity, diag.message)
		if diag.source then
			line_info = line_info .. " (" .. diag.source .. ")"
		end

		table.insert(formatted, line_info)
	end

	return table.concat(formatted, "\n")
end

-- Send selection to chat for adding debug code (shows in input, doesn't send automatically)
function M.send_selection_to_chat_for_debug()
	local text = M.get_selection()
	if not text or text == "" then
		print("No text selected!")
		return
	end

	-- Store selection context for later editing
	M.store_selection_context()

	-- Get LSP diagnostics for the selected code
	local diagnostics = M.get_lsp_diagnostics_for_selection()
	local lsp_info = M.format_lsp_diagnostics(diagnostics)

	-- Create the debug prompt with the selected code and LSP errors
	local debug_prompt = "Add debug code, logging statements, and print statements to help debug this code. Add variable inspection, error handling, and debugging utilities:\n\n```\n"
		.. text
		.. "\n```"

	-- Add LSP diagnostics if available
	if lsp_info then
		debug_prompt = debug_prompt
			.. lsp_info
			.. "\n\nPlease address these LSP errors/warnings and add comprehensive debugging code."
	else
		debug_prompt = debug_prompt .. "\n\nProvide the code with comprehensive debugging additions and explanations."
	end

	-- Open chat window if not open
	if not chat_win or not vim.api.nvim_win_is_valid(chat_win) then
		M.toggle_chat_window()
		-- Wait a moment for the window to be created, then populate input
		vim.defer_fn(function()
			M.populate_input_for_editing(debug_prompt)
		end, 100)
	else
		-- Chat window is already open, populate input immediately
		M.populate_input_for_editing(debug_prompt)
	end
end

-- Send selection to chat input for code editing (shows in input, doesn't send automatically)
function M.send_selection_to_chat_for_editing()
	local text = M.get_selection()
	if not text or text == "" then
		print("No text selected!")
		return
	end

	-- Store selection context for later editing
	M.store_selection_context()

	-- Just send the selected code without extra prompt text
	local editing_prompt = text

	-- Open chat window if not open
	if not chat_win or not vim.api.nvim_win_is_valid(chat_win) then
		M.toggle_chat_window()
		-- Wait a moment for the window to be created, then populate input
		vim.defer_fn(function()
			M.populate_input_for_editing(editing_prompt)
		end, 100)
	else
		-- Chat window is already open, populate input immediately
		M.populate_input_for_editing(editing_prompt)
	end
end

-- Populate input buffer with editing prompt (user can review before sending)
function M.populate_input_for_editing(prompt)
	if input_buf and vim.api.nvim_buf_is_valid(input_buf) then
		local lines = vim.split(prompt, "\n")
		vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, lines)
		-- Focus the input window
		if input_win and vim.api.nvim_win_is_valid(input_win) then
			vim.api.nvim_set_current_win(input_win)
			-- Position cursor at the end
			vim.api.nvim_win_set_cursor(input_win, { #lines, 0 })
			vim.cmd("startinsert!")
		end
	end
end

-- Process code edit request
function M.process_code_edit_request(text)
	-- Add user message to chat (show the code they want to edit)
	M.add_to_chat(text .. "\n```", true)

	-- Show "thinking" indicator
	M.add_to_chat("Thinking...", false)

	-- Send to Ollama
	M.query_ollama_async(text, function(response)
		vim.schedule(function()
			-- Remove "thinking" indicator
			if chat_buf and vim.api.nvim_buf_is_valid(chat_buf) then
				vim.api.nvim_buf_set_option(chat_buf, "modifiable", true)
				local line_count = vim.api.nvim_buf_line_count(chat_buf)
				-- Remove last 2 lines ("Thinking..." and empty line)
				if line_count >= 2 then
					vim.api.nvim_buf_set_lines(chat_buf, line_count - 2, line_count, false, {})
				end
				vim.api.nvim_buf_set_option(chat_buf, "modifiable", false)
			end

			-- Add AI response
			if response and response ~= "" then
				M.add_to_chat(response, false)

				-- Check if response contains code that can be applied as edit
				local suggested_code = M.extract_code_from_response(response)
				if suggested_code then
					-- Store the suggested code for potential application
					pending_edit.suggested_code = suggested_code
					pending_edit.response_id = os.time() .. "_" .. math.random(1000)

					-- Show accept/deny options
					M.add_edit_options()
				end
			else
				M.add_to_chat("No response received from Ollama", false)
			end
		end)
	end)
end

-- Send selection to chat input for editing
function M.send_selection_to_chat()
	local text = M.get_selection()
	if not text or text == "" then
		print("No text selected!")
		return
	end

	-- Open chat window if not open
	if not chat_win or not vim.api.nvim_win_is_valid(chat_win) then
		M.toggle_chat_window()
		-- Wait a moment for the window to be created, then populate input
		vim.defer_fn(function()
			if input_buf and vim.api.nvim_buf_is_valid(input_buf) then
				local lines = vim.split(text, "\n")
				-- Add an empty line at the end for cursor positioning
				table.insert(lines, "")
				vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, lines)
				-- Focus the input window and position cursor on the empty line
				if input_win and vim.api.nvim_win_is_valid(input_win) then
					vim.api.nvim_set_current_win(input_win)
					-- Move cursor to the last (empty) line
					vim.api.nvim_win_set_cursor(input_win, { #lines, 0 })
					vim.cmd("startinsert")
				end
			end
		end, 100)
	else
		-- Chat window is already open, just populate the input
		if input_buf and vim.api.nvim_buf_is_valid(input_buf) then
			local lines = vim.split(text, "\n")
			-- Add an empty line at the end for cursor positioning
			table.insert(lines, "")
			vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, lines)
			-- Focus the input window and position cursor on the empty line
			if input_win and vim.api.nvim_win_is_valid(input_win) then
				vim.api.nvim_set_current_win(input_win)
				-- Move cursor to the last (empty) line
				vim.api.nvim_win_set_cursor(input_win, { #lines, 0 })
				vim.cmd("startinsert")
			end
		end
	end
end

-- Process message in chat window
function M.process_chat_message(message)
	-- Add user message to chat
	M.add_to_chat(message, true)

	-- Show "thinking" indicator
	M.add_to_chat("Thinking...", false)

	-- Send to Ollama
	M.query_ollama_async(message, function(response)
		vim.schedule(function()
			-- Remove "thinking" indicator
			if chat_buf and vim.api.nvim_buf_is_valid(chat_buf) then
				vim.api.nvim_buf_set_option(chat_buf, "modifiable", true)
				local line_count = vim.api.nvim_buf_line_count(chat_buf)
				-- Remove last 2 lines ("Thinking..." and empty line)
				if line_count >= 2 then
					vim.api.nvim_buf_set_lines(chat_buf, line_count - 2, line_count, false, {})
				end
				vim.api.nvim_buf_set_option(chat_buf, "modifiable", false)
			end

			-- Add AI response
			if response and response ~= "" then
				M.add_to_chat(response, false)
			else
				M.add_to_chat("No response received from Ollama", false)
			end
		end)
	end)
end

-- Focus chat input window
function M.focus_chat_input()
	if input_win and vim.api.nvim_win_is_valid(input_win) then
		vim.api.nvim_set_current_win(input_win)
		vim.cmd("startinsert")
	else
		print("Chat window is not open. Use <Space>oc to open it.")
	end
end

-- Focus chat history window
function M.focus_chat_history()
	if chat_win and vim.api.nvim_win_is_valid(chat_win) then
		vim.api.nvim_set_current_win(chat_win)
	else
		print("Chat window is not open. Use <Space>oc to open it.")
	end
end

-- Test function for debugging
function M.test_ollama()
	local test_text = "Hello, can you respond with just 'Hi there!'?"
	M.query_ollama_async(test_text, function(response)
		vim.schedule(function()
			M.show_response(response)
		end)
	end)
end

-- Debug function to test selection capture
function M.debug_selection()
	local text = M.get_selection()
	print("Selected text: '" .. (text or "[NIL]") .. "'")
	print("Length: " .. (text and #text or 0))
end

-- Debug function to test LSP diagnostics
function M.debug_lsp_diagnostics()
	local buf = vim.api.nvim_get_current_buf()
	local diagnostics = vim.diagnostic.get(buf)

	print("=== LSP Diagnostics Debug ===")
	print("Buffer: " .. buf)
	print("Total diagnostics in buffer: " .. #diagnostics)

	for i, diag in ipairs(diagnostics) do
		print(
			string.format(
				"[%d] Line %d (0-based: %d): [%s] %s",
				i,
				diag.lnum + 1,
				diag.lnum,
				(diag.severity == 1 and "ERROR")
					or (diag.severity == 2 and "WARNING")
					or (diag.severity == 3 and "INFO")
					or (diag.severity == 4 and "HINT")
					or "UNKNOWN",
				diag.message
			)
		)
		if diag.source then
			print("    Source: " .. diag.source)
		end
	end

	-- Test the selection range detection
	local current_line = vim.api.nvim_win_get_cursor(0)[1]
	local vstart = vim.fn.getpos("'<")
	local vend = vim.fn.getpos(">")

	print("\n=== Selection Range Debug ===")
	print("Current cursor line: " .. current_line)
	print("Visual start: " .. vim.inspect(vstart))
	print("Visual end: " .. vim.inspect(vend))

	if vstart[2] > 0 and vend[2] > 0 and (vstart[2] ~= vend[2] or vstart[3] ~= vend[3]) then
		print("Selection range: " .. vstart[2] .. " to " .. vend[2])
	else
		print("No visual selection, using current line: " .. current_line)
	end
end

-- تابع اصلی (برای quick queries)
function M.send_to_ollama()
	local text = M.get_selection()
	if not text or text == "" then
		return
	end

	M.query_ollama_async(text, function(response)
		vim.schedule(function()
			M.show_response(response)
		end)
	end)
end

return M
