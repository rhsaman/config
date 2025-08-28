-- AI Chat Plugin with Multi-Provider Support
-- Features:
-- - Ollama (local AI)
-- - OpenAI GPT-4
-- - Anthropic Claude
-- - Grok (xAI) - Free API
-- - Provider selection popup: <leader>op
-- - Code editing with AI suggestions
-- - LSP diagnostics integration

local M = {}

local clean_code_prompt = [[
You are an expert programmer. Rewrite the code I provide in a clean and concise way,
optimizing structure and formatting, and adding comments if necessary.
Do not write any explanations, analysis, or anything I didn't ask for.
Only return the improved, cleaned-up version of the code.
]]

-- API Provider Configuration
local providers = {
	ollama = {
		name = "Ollama",
		model = "qwen3:4b-instruct-2507-q4_K_M",
		endpoint = nil, -- Local
		api_key = nil, -- Not needed for local
	},
	openai = {
		name = "OpenAI",
		model = "gpt-4",
		endpoint = "https://api.openai.com/v1/chat/completions",
		api_key = os.getenv("OPENAI_API_KEY"),
	},
	cloud = {
		name = "Anthropic Claude",
		model = "claude-3-sonnet-20240229",
		endpoint = "https://api.anthropic.com/v1/messages",
		api_key = os.getenv("ANTHROPIC_API_KEY"),
	},
	grok = {
		name = "Grok (xAI)",
		model = "grok-beta",
		endpoint = "https://api.x.ai/v1/chat/completions",
		api_key = os.getenv("GROK_API_KEY"),
	},
}

-- Current active provider
local current_provider = "ollama"

-- Provider persistence
local provider_config_file = vim.fn.stdpath('data') .. '/ollama_chat_provider.json'

-- Load saved provider from file
function M.load_saved_provider()
	local file = io.open(provider_config_file, 'r')
	if file then
		local content = file:read('*all')
		file:close()

		local success, data = pcall(vim.json.decode, content)
		if success and data and data.provider and providers[data.provider] then
			-- Validate that the provider's API key is still available
			local valid, error_msg = M.validate_api_key(data.provider)
			if valid then
				current_provider = data.provider
				return true
			else
				print("Warning: Saved provider '" .. data.provider .. "' is no longer available: " .. error_msg)
				print("Falling back to Ollama")
				return false
			end
		else
			return false
		end
	else
		return false
	end
end

-- Save current provider to file
function M.save_current_provider()
	local data = {
		provider = current_provider,
		timestamp = os.time(),
		version = "1.0"
	}

	local success, encoded = pcall(vim.json.encode, data)
	if success then
		local file = io.open(provider_config_file, 'w')
		if file then
			file:write(encoded)
			file:close()
			return true
		end
	end
	return false
end

-- Chat window state
local chat_win = nil
local chat_buf = nil
local input_buf = nil
local input_win = nil
local chat_history = {}
local current_job = nil -- Track current API job

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

-- Module state
M._provider_initialized = false
M.provider_popup = nil

-- Validate API key for a provider
function M.validate_api_key(provider)
	if provider == "ollama" then
		return true
	elseif provider == "openai" then
		if not providers.openai.api_key or providers.openai.api_key == "" then
			return false, "OpenAI API key not found. Set OPENAI_API_KEY environment variable."
		end
	elseif provider == "cloud" then
		if not providers.cloud.api_key or providers.cloud.api_key == "" then
			return false, "Anthropic API key not found. Set ANTHROPIC_API_KEY environment variable."
		end
	elseif provider == "grok" then
		if not providers.grok.api_key or providers.grok.api_key == "" then
			return false, "Grok API key not found. Set GROK_API_KEY environment variable."
		end
	end
	return true
end

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

-- گرفتن متن انتخابی یا خط جاری
function M.get_selection()
	-- First try to get visual selection if we were just in visual mode
	local vstart = vim.fn.getpos("'<")
	local vend = vim.fn.getpos("'>")

	-- Check if we have a valid visual selection
	if vstart[2] > 0 and vend[2] > 0 and (vstart[2] ~= vend[2] or vstart[3] ~= vend[3]) then
		local lines = vim.fn.getline(vstart[2], vend[2])

		-- اگه فقط یه خط باشه، `vim.fn.getline` یه string میده → باید بکنیمش table
		if type(lines) == "string" then
			lines = { lines }
		end

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

-- Store the current selection context for later editing
function M.store_selection_context()
	local buf = vim.api.nvim_get_current_buf()
	local vstart = vim.fn.getpos("'<")
	local vend = vim.fn.getpos("'>")

	-- Check if we have a valid visual selection
	if vstart[2] > 0 and vend[2] > 0 and (vstart[2] ~= vend[2] or vstart[3] ~= vend[3]) then
		-- We have a valid visual selection
		pending_edit.original_buf = buf
		pending_edit.original_start_line = vstart[2]
		pending_edit.original_end_line = vend[2]
		pending_edit.original_start_col = vstart[3]
		pending_edit.original_end_col = vend[3]
	else
		-- No visual selection, use current line
		local current_line = vim.api.nvim_win_get_cursor(0)[1]
		local line_text = vim.api.nvim_get_current_line()

		pending_edit.original_buf = buf
		pending_edit.original_start_line = current_line
		pending_edit.original_end_line = current_line
		pending_edit.original_start_col = 1
		pending_edit.original_end_col = #line_text
	end

	return buf, vstart, vend
end

-- اجرای Ollama API async (truly async using jobstart)
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

	local cmd = {
		"sh", "-c", string.format('timeout 15s cat "%s" | ollama run qwen3:4b-instruct-2507-q4_K_M 2>/dev/null | head -10', temp_file)
	}

	local response_lines = {}
	local callback_called = false

	-- Add timeout to prevent hanging
	vim.defer_fn(function()
		if current_job and not callback_called then
			vim.fn.jobstop(current_job)
			current_job = nil
			if not callback_called then
				callback_called = true
				print("Ollama job timed out, trying fallback...")
				local fallback_response = M.try_sync_ollama(clean_text)
				if fallback_response then
					callback(fallback_response .. " (timed out, via fallback)")
				else
					callback("Ollama request timed out")
				end
			end
		end
	end, 10000) -- 10 second timeout

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
		on_stderr = function(_, _)
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

						callback(final_response)
					else
						-- Try synchronous fallback
						print("Ollama async failed, trying synchronous fallback...")
						local fallback_response = M.try_sync_ollama(clean_text)
						if fallback_response then
							callback(fallback_response .. " (via fallback)")
						else
							callback("No response from Ollama (empty response)")
						end
					end
				else
					-- Try synchronous fallback on failure
					print("Ollama command failed (exit code: " .. exit_code .. "), trying synchronous fallback...")
					local fallback_response = M.try_sync_ollama(clean_text)
					if fallback_response then
						callback(fallback_response .. " (via fallback)")
					else
						callback("Ollama command failed with exit code: " .. exit_code)
					end
				end
			end
		end,
	})
end

-- اجرای OpenAI API async
function M.query_openai_async(text, callback)
	-- Check if API key is available
	if not providers.openai.api_key then
		callback("Error: OpenAI API key not found. Set OPENAI_API_KEY environment variable.")
		return
	end

	-- Clean and prepare text
	local clean_text = text:gsub('"', '\\"'):gsub("\n", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")

	if clean_text == "" then
		callback("Error: Empty text provided")
		return
	end

	-- Create request payload
	local payload = {
		model = providers.openai.model,
		messages = {
			{ role = "user", content = clean_text }
		},
		max_tokens = 4096,
		temperature = 0.7
	}

	local json_payload = vim.json.encode(payload)

	-- Create temporary file for payload
	local temp_file = vim.fn.tempname()
	vim.fn.writefile({ json_payload }, temp_file)

	local cmd = {
		"curl",
		"-s",
		"-X", "POST",
		"-H", "Content-Type: application/json",
		"-H", "Authorization: Bearer " .. providers.openai.api_key,
		"-d", "@" .. temp_file,
		providers.openai.endpoint
	}

	local response_lines = {}
	local callback_called = false

	current_job = vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if data and #data > 0 then
				for _, line in ipairs(data) do
					if line and line ~= "" then
						table.insert(response_lines, line)
					end
				end
			end
		end,
		on_stderr = function(_, _)
			-- Silently handle errors
		end,
		on_exit = function(_, exit_code)
			-- Clean up temp file
			vim.fn.delete(temp_file)

			if not callback_called then
				callback_called = true

				if exit_code == 0 then
					if #response_lines > 0 then
						local response_json = table.concat(response_lines, "")
						local success, response_data = pcall(vim.json.decode, response_json)

						if success and response_data.choices and response_data.choices[1] then
							local content = response_data.choices[1].message.content
							if content then
								callback(content)
							else
								callback("No content in OpenAI response")
							end
						else
							callback("Failed to parse OpenAI response: " .. response_json)
						end
					else
						callback("No response from OpenAI")
					end
				else
					callback("OpenAI API request failed with exit code: " .. exit_code)
				end
			end
		end,
	})
end

-- اجرای Cloud API (Anthropic Claude) async
function M.query_cloud_async(text, callback)
	-- Check if API key is available
	if not providers.cloud.api_key then
		callback("Error: Anthropic API key not found. Set ANTHROPIC_API_KEY environment variable.")
		return
	end

	-- Clean and prepare text
	local clean_text = text:gsub('"', '\\"'):gsub("\n", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")

	if clean_text == "" then
		callback("Error: Empty text provided")
		return
	end

	-- Create request payload for Anthropic
	local payload = {
		model = providers.cloud.model,
		max_tokens = 4096,
		messages = {
			{ role = "user", content = clean_text }
		}
	}

	local json_payload = vim.json.encode(payload)

	-- Create temporary file for payload
	local temp_file = vim.fn.tempname()
	vim.fn.writefile({ json_payload }, temp_file)

	local cmd = {
		"curl",
		"-s",
		"-X", "POST",
		"-H", "Content-Type: application/json",
		"-H", "x-api-key: " .. providers.cloud.api_key,
		"-H", "anthropic-version: 2023-06-01",
		"-d", "@" .. temp_file,
		providers.cloud.endpoint
	}

	local response_lines = {}
	local callback_called = false

	current_job = vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if data and #data > 0 then
				for _, line in ipairs(data) do
					if line and line ~= "" then
						table.insert(response_lines, line)
					end
				end
			end
		end,
		on_stderr = function(_, _)
			-- Silently handle errors
		end,
		on_exit = function(_, exit_code)
			-- Clean up temp file
			vim.fn.delete(temp_file)

			if not callback_called then
				callback_called = true

				if exit_code == 0 then
					if #response_lines > 0 then
						local response_json = table.concat(response_lines, "")
						local success, response_data = pcall(vim.json.decode, response_json)

						if success and response_data.content and response_data.content[1] then
							local content = response_data.content[1].text
							if content then
								callback(content)
							else
								callback("No content in Claude response")
							end
						else
							callback("Failed to parse Claude response: " .. response_json)
						end
					else
						callback("No response from Claude")
					end
				else
					callback("Claude API request failed with exit code: " .. exit_code)
				end
			end
		end,
	})
end

-- اجرای Grok API async (xAI)
function M.query_grok_async(text, callback)
	-- Check if API key is available
	if not providers.grok.api_key then
		callback("Error: Grok API key not found. Set GROK_API_KEY environment variable.")
		return
	end

	-- Clean and prepare text
	local clean_text = text:gsub('"', '\\"'):gsub("\n", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")

	if clean_text == "" then
		callback("Error: Empty text provided")
		return
	end

	-- Create request payload (similar to OpenAI format)
	local payload = {
		model = providers.grok.model,
		messages = {
			{ role = "user", content = clean_text }
		},
		max_tokens = 4096,
		temperature = 0.7
	}

	local json_payload = vim.json.encode(payload)

	-- Create temporary file for payload
	local temp_file = vim.fn.tempname()
	vim.fn.writefile({ json_payload }, temp_file)

	local cmd = {
		"curl",
		"-s",
		"-X", "POST",
		"-H", "Content-Type: application/json",
		"-H", "Authorization: Bearer " .. providers.grok.api_key,
		"-d", "@" .. temp_file,
		providers.grok.endpoint
	}

	local response_lines = {}
	local callback_called = false

	current_job = vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if data and #data > 0 then
				for _, line in ipairs(data) do
					if line and line ~= "" then
						table.insert(response_lines, line)
					end
				end
			end
		end,
		on_stderr = function(_, _)
			-- Silently handle errors
		end,
		on_exit = function(_, exit_code)
			-- Clean up temp file
			vim.fn.delete(temp_file)

			if not callback_called then
				callback_called = true

				if exit_code == 0 then
					if #response_lines > 0 then
						local response_json = table.concat(response_lines, "")
						local success, response_data = pcall(vim.json.decode, response_json)

						if success and response_data.choices and response_data.choices[1] then
							local content = response_data.choices[1].message.content
							if content then
								callback(content)
							else
								callback("No content in Grok response")
							end
						else
							callback("Failed to parse Grok response: " .. response_json)
						end
					else
						callback("No response from Grok")
					end
				else
					callback("Grok API request failed with exit code: " .. exit_code)
				end
			end
		end,
	})
end

-- Synchronous fallback for Ollama queries
function M.try_sync_ollama(text)
	local temp_file = vim.fn.tempname()
	vim.fn.writefile({ text }, temp_file)

	local cmd = string.format('timeout 10s cat "%s" | ollama run qwen3:4b-instruct-2507-q4_K_M 2>/dev/null | head -5', temp_file)
	local handle = io.popen(cmd)

	if handle then
		local result = handle:read("*a")
		handle:close()
		vim.fn.delete(temp_file)

		if result and result ~= "" then
			-- Clean up the response
			result = result:gsub("\n+", " "):gsub("^%s*", ""):gsub("%s*$", "")
			if #result > 500 then
				result = result:sub(1, 500) .. "..."
			end
			return result
		end
	end

	vim.fn.delete(temp_file)
	return nil
end

-- Get current provider (for testing/debugging)
function M.get_current_provider()
	return current_provider
end

-- Unified query function that routes to the current provider
function M.query_ai_async(text, callback)
	local valid, error_msg = M.validate_api_key(current_provider)
	if not valid then
		callback("Error: " .. error_msg)
		return
	end

	if current_provider == "ollama" then
		M.query_ollama_async(text, callback)
	elseif current_provider == "openai" then
		M.query_openai_async(text, callback)
	elseif current_provider == "cloud" then
		M.query_cloud_async(text, callback)
	elseif current_provider == "grok" then
		M.query_grok_async(text, callback)
	else
		callback("Error: Unknown provider '" .. current_provider .. "'")
	end
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
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

-- Apply code edit to original buffer (without switching to it)
function M.accept_code_edit()
	if
		not pending_edit.original_buf
		or not pending_edit.suggested_code
		or not vim.api.nvim_buf_is_valid(pending_edit.original_buf)
	then
		return
	end

	-- Remember current window to return to it later
	local current_win = vim.api.nvim_get_current_win()

	-- Get buffer info for validation
	local buf_line_count = vim.api.nvim_buf_line_count(pending_edit.original_buf)

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

	-- Use nvim_buf_set_text for precise text replacement
	local start_row = start_line - 1
	local start_col_0 = start_col - 1
	local end_row = end_line - 1
	local end_col_0 = end_col - 1

	-- Validate buffer is modifiable
	if not vim.bo[pending_edit.original_buf].modifiable then
		return
	end

	-- Validate positions are within bounds
	local buf_line_count = vim.api.nvim_buf_line_count(pending_edit.original_buf)
	if start_row < 0 or start_row >= buf_line_count or end_row < 0 or end_row >= buf_line_count then
		return
	end

	-- Get the line lengths to validate column positions
	local start_line_text = vim.api.nvim_buf_get_lines(pending_edit.original_buf, start_row, start_row + 1, false)[1]
		or ""
	local end_line_text = vim.api.nvim_buf_get_lines(pending_edit.original_buf, end_row, end_row + 1, false)[1] or ""

	if start_col_0 < 0 or start_col_0 > #start_line_text then
		return
	end

	-- For end_col, since it's exclusive, it can be equal to line length
	if end_col_0 < 0 or end_col_0 > #end_line_text then
		return
	end

	-- Replace the selection with the new code
	local success, err = pcall(function()
		vim.api.nvim_buf_set_text(pending_edit.original_buf, start_row, start_col_0, end_row, end_col_0, code_lines)
	end)

	if not success then
		return
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

	-- Keep the AI response in chat, just remove accept/deny options
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
end

-- Clear edit options from chat window (keeps AI response, removes only options)
function M.clear_edit_options()
	if chat_buf and vim.api.nvim_buf_is_valid(chat_buf) then
		vim.api.nvim_set_option_value("modifiable", true, { buf = chat_buf })
		local lines = vim.api.nvim_buf_get_lines(chat_buf, 0, -1, false)

		-- Remove only the accept/deny option lines, keep everything else
		local new_lines = {}
		for _, line in ipairs(lines) do
			if not line:match("^%[ACCEPT%]") and not line:match("^%[DENY%]") and not line:match("^>>> Press") then
				table.insert(new_lines, line)
			end
		end

		vim.api.nvim_buf_set_lines(chat_buf, 0, -1, false, new_lines)
		vim.api.nvim_set_option_value("modifiable", false, { buf = chat_buf })
	end
end

-- Add accept/deny options to chat
function M.add_edit_options()
	if chat_buf and vim.api.nvim_buf_is_valid(chat_buf) then
		vim.api.nvim_set_option_value("modifiable", true, { buf = chat_buf })
		local options = {
			"",
			">>> Press 'a' to ACCEPT this code edit or 'd' to DENY it <<<",
			"[ACCEPT] - Apply the suggested code to your original selection",
			"[DENY] - Reject the code edit",
			"",
		}
		vim.api.nvim_buf_set_lines(chat_buf, -1, -1, false, options)
		vim.api.nvim_set_option_value("modifiable", false, { buf = chat_buf })

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
		vim.api.nvim_set_option_value("modifiable", true, { buf = chat_buf })

		vim.api.nvim_buf_set_lines(chat_buf, -1, -1, false, vim.split(formatted_message, "\n"))
		vim.api.nvim_buf_set_lines(chat_buf, -1, -1, false, { "" })
		vim.api.nvim_set_option_value("modifiable", false, { buf = chat_buf })

		-- Auto scroll to bottom
		if chat_win and vim.api.nvim_win_is_valid(chat_win) then
			local line_count = vim.api.nvim_buf_line_count(chat_buf)
			vim.api.nvim_win_set_cursor(chat_win, { line_count, 0 })
		end
	end
end

-- Initialize provider (load saved or use default)
function M.initialize_provider()
	if not M.load_saved_provider() then
		-- If no saved provider or invalid, use default
		current_provider = "ollama"
	end
end

-- Create or show chat window as resizable panes
function M.toggle_chat_window()
	-- Initialize provider on first use
	if not M._provider_initialized then
		M.initialize_provider()
		M._provider_initialized = true
	end

	-- Check if chat windows exist and are valid
	local chat_exists = chat_win and vim.api.nvim_win_is_valid(chat_win)
	local input_exists = input_win and vim.api.nvim_win_is_valid(input_win)

	if chat_exists or input_exists then
		-- Close chat windows
		if chat_exists and chat_win then
			vim.api.nvim_win_close(chat_win, true)
		end
		if input_exists and input_win then
			vim.api.nvim_win_close(input_win, true)
		end
		chat_win = nil
		input_win = nil
		return
	end

	-- Create chat buffer if it doesn't exist
	if not chat_buf or not vim.api.nvim_buf_is_valid(chat_buf) then
		chat_buf = vim.api.nvim_create_buf(false, true)
		vim.bo[chat_buf].buftype = "nofile"
		vim.bo[chat_buf].swapfile = false
		vim.bo[chat_buf].filetype = "markdown"
		vim.api.nvim_buf_set_name(chat_buf, "[" .. providers[current_provider].name .. " Chat]")

		-- Add welcome message
		local welcome = "=== " .. providers[current_provider].name .. " Chat ==="
		local help_text = {
			"Provider selection: <leader>op (popup menu)",
			"Reset to default: <leader>pd (Ollama)",
			"Provider status: <leader>ps | Config info: <leader>pi",
			"Legacy switching: <leader>po (Ollama), <leader>pg (GPT), <leader>pc (Claude), <leader>pk (Grok)",
			"Accept/Deny edits: 'a' / 'd'",
			"💾 Provider preference is automatically saved",
			"",
		}
		local lines = { welcome, "" }
		for _, line in ipairs(help_text) do
			table.insert(lines, line)
		end
		vim.api.nvim_buf_set_lines(chat_buf, 0, -1, false, lines)
		vim.bo[chat_buf].modifiable = false
	end

	-- Create input buffer if it doesn't exist
	if not input_buf or not vim.api.nvim_buf_is_valid(input_buf) then
		input_buf = vim.api.nvim_create_buf(false, true)
		vim.bo[input_buf].buftype = "nofile"
		vim.bo[input_buf].swapfile = false
		vim.bo[input_buf].filetype = "text"
		vim.api.nvim_buf_set_name(input_buf, "[Ollama Input]")
	end

	-- Create vertical split on the right (40% width)
	vim.cmd("rightbelow 50vnew")
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
	vim.api.nvim_buf_set_keymap(
		input_buf,
		"n",
		"<leader>op",
		":lua require('config.ollama_chat').show_provider_popup()<CR>",
		{ noremap = true, silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		input_buf,
		"n",
		"<leader>pd",
		":lua require('config.ollama_chat').reset_provider_to_default()<CR>",
		{ noremap = true, silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		input_buf,
		"n",
		"<leader>ps",
		":lua require('config.ollama_chat').show_provider_status()<CR>",
		{ noremap = true, silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		input_buf,
		"n",
		"<leader>pi",
		":lua require('config.ollama_chat').show_provider_config_info()<CR>",
		{ noremap = true, silent = true }
	)
	-- Add Grok provider keybinding
	vim.api.nvim_buf_set_keymap(
		input_buf,
		"n",
		"<leader>pk",
		":lua require('config.ollama_chat').switch_provider('grok')<CR>",
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

	-- Add provider selection popup keybinding
	vim.api.nvim_buf_set_keymap(
		chat_buf,
		"n",
		"<leader>op",
		":lua require('config.ollama_chat').show_provider_popup()<CR>",
		{ noremap = true, silent = true }
	)
	-- Add reset to default provider keybinding
	vim.api.nvim_buf_set_keymap(
		chat_buf,
		"n",
		"<leader>pd",
		":lua require('config.ollama_chat').reset_provider_to_default()<CR>",
		{ noremap = true, silent = true }
	)
	-- Add detailed config info keybinding
	vim.api.nvim_buf_set_keymap(
		chat_buf,
		"n",
		"<leader>pi",
		":lua require('config.ollama_chat').show_provider_config_info()<CR>",
		{ noremap = true, silent = true }
	)

	-- Add legacy provider switching keybindings (for backward compatibility)
	vim.api.nvim_buf_set_keymap(
		chat_buf,
		"n",
		"<leader>po",
		":lua require('config.ollama_chat').switch_provider('ollama')<CR>",
		{ noremap = true, silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		chat_buf,
		"n",
		"<leader>pg",
		":lua require('config.ollama_chat').switch_provider('openai')<CR>",
		{ noremap = true, silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		chat_buf,
		"n",
		"<leader>pc",
		":lua require('config.ollama_chat').switch_provider('cloud')<CR>",
		{ noremap = true, silent = true }
	)
	-- Add Grok provider keybinding
	vim.api.nvim_buf_set_keymap(
		chat_buf,
		"n",
		"<leader>pk",
		":lua require('config.ollama_chat').switch_provider('grok')<CR>",
		{ noremap = true, silent = true }
	)

	-- Enter insert mode in input window
	vim.cmd("startinsert")
end

-- Switch to a different provider
function M.switch_provider(provider)
	-- Initialize provider if not already done
	if not M._provider_initialized then
		M.initialize_provider()
		M._provider_initialized = true
	end

	if providers[provider] then
		local valid, error_msg = M.validate_api_key(provider)
		if not valid then
			print("Error: " .. error_msg)
			return
		end

		local old_provider = current_provider
		current_provider = provider

		-- Save the new provider setting
		local saved = M.save_current_provider()
		if not saved then
			print("Warning: Could not save provider preference")
		end

		if chat_buf and vim.api.nvim_buf_is_valid(chat_buf) then
			-- Update chat header to show current provider
			local header = "=== " .. providers[provider].name .. " Chat ==="
			vim.api.nvim_set_option_value("modifiable", true, { buf = chat_buf })
			vim.api.nvim_buf_set_lines(chat_buf, 0, 1, false, { header, "" })
			vim.api.nvim_set_option_value("modifiable", false, { buf = chat_buf })
		end

		if old_provider ~= provider then
			local save_status = saved and " (saved)" or " (not saved)"
			print("Switched to " .. providers[provider].name .. save_status)
		end
	else
		print("Error: Unknown provider '" .. provider .. "'")
	end
end

-- Show current provider status
function M.show_provider_status()
	-- Initialize provider if not already done
	if not M._provider_initialized then
		M.initialize_provider()
		M._provider_initialized = true
	end

	local status = "Current provider: " .. providers[current_provider].name
	if current_provider ~= "ollama" then
		local valid, error_msg = M.validate_api_key(current_provider)
		if not valid then
			status = status .. " (API key missing: " .. error_msg .. ")"
		else
			status = status .. " (API key configured)"
		end
	end

	-- Show persistence info
	local file_exists = vim.fn.filereadable(provider_config_file) == 1
	if file_exists then
		status = status .. " (saved)"
	else
		status = status .. " (not saved)"
	end

	print(status)
end

-- Show detailed provider configuration info
function M.show_provider_config_info()
	print("=== AI Chat Provider Configuration ===")
	print("Config file: " .. provider_config_file)
	print("Current provider: " .. providers[current_provider].name)

	local file_exists = vim.fn.filereadable(provider_config_file) == 1
	if file_exists then
		local file = io.open(provider_config_file, 'r')
		if file then
			local content = file:read('*all')
			file:close()
			local success, data = pcall(vim.json.decode, content)
			if success and data then
				print("Saved provider: " .. (data.provider or "none"))
				if data.timestamp then
					print("Last saved: " .. os.date("%Y-%m-%d %H:%M:%S", data.timestamp))
				end
			end
		end
	else
		print("No saved configuration found")
	end

	print("\nAvailable providers:")
	for key, provider in pairs(providers) do
		local status = ""
		if key ~= "ollama" then
			local valid, error_msg = M.validate_api_key(key)
			if not valid then
				status = " (API key missing)"
			else
				status = " (configured)"
			end
		else
			status = " (local)"
		end
		local current_marker = (key == current_provider) and " ← current" or ""
		print("  " .. provider.name .. status .. current_marker)
	end
end

-- Show provider selection popup
function M.show_provider_popup()
	-- Initialize provider if not already done
	if not M._provider_initialized then
		M.initialize_provider()
		M._provider_initialized = true
	end

	local options = {}
	local option_keys = {}

	for key, provider in pairs(providers) do
		local status = ""
		if key ~= "ollama" then
			local valid, error_msg = M.validate_api_key(key)
			if not valid then
				status = " (⚠️  API key missing)"
			else
				status = " (✅ configured)"
			end
		else
			status = " (🏠 local)"
		end

		local display_name = provider.name .. status
		if key == current_provider then
			display_name = "● " .. display_name .. " (current)"
		else
			display_name = "○ " .. display_name
		end

		table.insert(options, display_name)
		table.insert(option_keys, key)
	end

	-- Try vim.ui.select first, fallback to custom popup
	if vim.ui and vim.ui.select then
		vim.ui.select(options, {
			prompt = "Select AI Provider:",
			format_item = function(item)
				return item
			end,
		}, function(choice, idx)
			if choice and idx then
				local selected_provider = option_keys[idx]
				M.switch_provider(selected_provider)
			end
		end)
	else
		-- Fallback: create a simple floating window popup
		M.show_custom_provider_popup(options, option_keys)
	end
end

-- Custom floating window popup for provider selection
function M.show_custom_provider_popup(options, option_keys)
	local width = 50
	local height = #options + 2
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	-- Create buffer
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
	vim.api.nvim_buf_set_option(buf, 'swapfile', false)

	-- Create window
	local win = vim.api.nvim_open_win(buf, true, {
		relative = 'editor',
		width = width,
		height = height,
		row = row,
		col = col,
		style = 'minimal',
		border = 'rounded',
	})

	-- Set content
	local lines = { "Select AI Provider:", "" }
	for i, option in ipairs(options) do
		table.insert(lines, string.format("%d. %s", i, option))
	end
	table.insert(lines, "")
	table.insert(lines, "Press number key to select, Esc to cancel")

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	-- Set keymaps for selection
	for i = 1, #options do
		vim.api.nvim_buf_set_keymap(buf, 'n', tostring(i), string.format(
			':lua require("config.ollama_chat").select_provider_from_popup(%d)<CR>',
			i
		), { noremap = true, silent = true })
	end

	vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':lua require("config.ollama_chat").close_provider_popup()<CR>', { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':lua require("config.ollama_chat").close_provider_popup()<CR>', { noremap = true, silent = true })

	-- Store popup state
	M.provider_popup = {
		win = win,
		buf = buf,
		options = option_keys
	}

	-- Enter insert mode to make it more obvious it's interactive
	vim.cmd('startinsert')
end

-- Select provider from popup
function M.select_provider_from_popup(index)
	if M.provider_popup and M.provider_popup.options[index] then
		local selected_provider = M.provider_popup.options[index]
		M.close_provider_popup()
		M.switch_provider(selected_provider)
	end
end

-- Close provider popup
function M.close_provider_popup()
	if M.provider_popup then
		if vim.api.nvim_win_is_valid(M.provider_popup.win) then
			vim.api.nvim_win_close(M.provider_popup.win, true)
		end
		if vim.api.nvim_buf_is_valid(M.provider_popup.buf) then
			vim.api.nvim_buf_delete(M.provider_popup.buf, { force = true })
		end
		M.provider_popup = nil
	end
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

	-- Send to AI provider
	M.query_ai_async(message, function(response)
		vim.schedule(function()
			-- Remove "thinking" indicator
			if chat_buf and vim.api.nvim_buf_is_valid(chat_buf) then
				vim.bo[chat_buf].modifiable = true
				local line_count = vim.api.nvim_buf_line_count(chat_buf)
				-- Remove last 2 lines ("Thinking..." and empty line)
				if line_count >= 2 then
					vim.api.nvim_buf_set_lines(chat_buf, line_count - 2, line_count, false, {})
				end
				vim.bo[chat_buf].modifiable = false
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

	-- Get all diagnostics for the current buffer
	local diagnostics = vim.diagnostic.get(buf)

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

	-- If we only found a few diagnostics in the selection, but there are many similar ones,
	-- include some of the similar ones to give better context
	if #relevant_diagnostics < 3 and #similar_diagnostics > #relevant_diagnostics then
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
	local debug_prompt = clean_code_prompt .. "\n\n" .. text
	-- Add LSP diagnostics if available
	if lsp_info then
		debug_prompt = debug_prompt .. lsp_info .. "\n\n fix it"
	else
		debug_prompt = debug_prompt .. "\n\nfix it"
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
	local editing_prompt = clean_code_prompt .. "\n\n" .. text

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

	-- Send to AI provider
	M.query_ai_async(text, function(response)
		vim.schedule(function()
			-- Remove "thinking" indicator
			if chat_buf and vim.api.nvim_buf_is_valid(chat_buf) then
				vim.bo[chat_buf].modifiable = false
				local line_count = vim.api.nvim_buf_line_count(chat_buf)
				-- Remove last 2 lines ("Thinking..." and empty line)
				if line_count >= 2 then
					vim.api.nvim_buf_set_lines(chat_buf, line_count - 2, line_count, false, {})
				end
				vim.bo[chat_buf].modifiable = false
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

	-- Send to AI provider
	M.query_ai_async(message, function(response)
		vim.schedule(function()
			-- Remove "thinking" indicator
			if chat_buf and vim.api.nvim_buf_is_valid(chat_buf) then
				vim.bo[chat_buf].modifiable = true

				local line_count = vim.api.nvim_buf_line_count(chat_buf)
				-- Remove last 2 lines ("Thinking..." and empty line)
				if line_count >= 2 then
					vim.api.nvim_buf_set_lines(chat_buf, line_count - 2, line_count, false, {})
				end
				vim.bo[chat_buf].modifiable = false
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

-- Test function for debugging
function M.test_ai()
	local test_text = "Hello, can you respond with just 'Hi there!'?"
	M.query_ai_async(test_text, function(response)
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
function M.send_to_ai()
	local text = M.get_selection()
	if not text or text == "" then
		return
	end

	M.query_ai_async(text, function(response)
		vim.schedule(function()
			M.show_response(response)
		end)
	end)
end

-- Global function to show provider popup from anywhere
function M.select_provider_global()
	M.show_provider_popup()
end

-- Test Ollama connection
function M.test_ollama_connection()
	print("Testing Ollama connection...")

	local test_text = "Hello, respond with just 'OK' if you can hear me."

	M.query_ollama_async(test_text, function(response)
		vim.schedule(function()
			print("Ollama test response: " .. (response or "nil"))
		end)
	end)
end

-- Simple synchronous Ollama test
function M.test_ollama_simple()
	print("Testing simple Ollama command...")

	local handle = io.popen('echo "Hi" | timeout 10s ollama run qwen3:4b-instruct-2507-q4_K_M 2>/dev/null | head -5')
	if handle then
		local result = handle:read("*a")
		handle:close()
		print("Simple test result:")
		print(result)
	else
		print("Failed to run simple test")
	end
end

-- Test provider persistence (for debugging)
function M.test_provider_persistence()
	print("=== Testing Provider Persistence ===")

	-- Test saving
	local original_provider = current_provider
	current_provider = "openai"
	local saved = M.save_current_provider()
	print("Save test: " .. (saved and "SUCCESS" or "FAILED"))

	-- Test loading
	current_provider = "ollama" -- Reset to different value
	local loaded = M.load_saved_provider()
	print("Load test: " .. (loaded and "SUCCESS" or "FAILED"))
	print("Loaded provider: " .. current_provider)

	-- Restore original
	current_provider = original_provider
	M.save_current_provider()
	print("Restored original provider: " .. current_provider)
end

return M
